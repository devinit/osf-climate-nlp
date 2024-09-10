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

card = 'alex-miller/ODABert'
tokenizer = AutoTokenizer.from_pretrained(card, model_max_length=512)
data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

dataset = load_dataset('devinitorg/wb-climate-percentage')
dataset = dataset.remove_columns(
    ['id', 'Climate change']
)

def preprocess_function(example):
    labels = [example['Climate adaptation'], example['Climate mitigation']]
    example = tokenizer(example['text'], truncation=True)
    example['labels'] = labels
    return example

dataset = dataset.map(preprocess_function, remove_columns=['text', 'Climate adaptation', 'Climate mitigation'])

model = AutoModelForSequenceClassification.from_pretrained(
    card,
    num_labels=2,
    problem_type='regression'
)

training_args = TrainingArguments(
    'climate-dual-percentage-regression',
    learning_rate=8e-7,
    per_device_train_batch_size=24,
    per_device_eval_batch_size=24,
    num_train_epochs=10,
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
)

trainer.train()
trainer.push_to_hub()