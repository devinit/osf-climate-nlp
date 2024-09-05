from huggingface_hub import login
from datasets import load_dataset
from dotenv import load_dotenv
import os
from collections import Counter


def bin_labels(example):
    example['class_label'] = example['Climate change'] == 0.
    return example


def main():
    dataset = load_dataset("csv", data_files="./input/world_bank_climate_percentages.csv", split="train")
    dataset = dataset.map(bin_labels)

    count = Counter()
    count.update(dataset['class_label'])
    print(count)

    dataset = dataset.class_encode_column('class_label').train_test_split(
        test_size=0.2,
        stratify_by_column="class_label",
        shuffle=True,
        seed=1337
    )
    dataset = dataset.remove_columns(['class_label'])
    dataset.push_to_hub("devinitorg/wb-climate-percentage")


if __name__ == '__main__':
    load_dotenv()
    HF_TOKEN = os.getenv('HF_TOKEN')
    login(token=HF_TOKEN)
    main()
