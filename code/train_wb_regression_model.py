# ! pip install datasets evaluate transformers accelerate huggingface_hub --quiet

# from huggingface_hub import login

# login()

from datasets import load_dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    DataCollatorWithPadding,
    TrainingArguments,
    Trainer
)
import evaluate


card = 'alex-miller/ODABert'
tokenizer = AutoTokenizer.from_pretrained(card, model_max_length=512)
data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

dataset = load_dataset('devinitorg/wb-climate-percentage')
dataset = dataset.rename_column('Climate change', 'label')
dataset = dataset.remove_columns(
    ['id', 'Climate mitigation', 'Climate adaptation']
)

def preprocess_function(example):
    example = tokenizer(example['text'], truncation=True)
    return example

dataset = dataset.map(preprocess_function, remove_columns=['text'])

metric = evaluate.load('mse')
def compute_metrics(eval_pred):
    predictions, labels = eval_pred
    mse = metric.compute(predictions=predictions, references=labels)
    return mse

model = AutoModelForSequenceClassification.from_pretrained(
    card,
    num_labels=1, 
    problem_type='regression'
)

training_args = TrainingArguments(
    'climate-percentage-regression',
    learning_rate=8e-7,
    per_device_train_batch_size=24,
    per_device_eval_batch_size=24,
    num_train_epochs=20,
    weight_decay=0.01,
    eval_strategy='epoch',
    save_strategy='epoch',
    logging_strategy='epoch',
    load_best_model_at_end=True,
    push_to_hub=True,
    save_total_limit=5,
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset['train'],
    eval_dataset=dataset['test'],
    tokenizer=tokenizer,
    data_collator=data_collator,
    compute_metrics=compute_metrics,
)

trainer.train()
trainer.push_to_hub()