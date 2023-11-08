import argparse
import uuid

import pandas as pd


def update_csv_with_uuid(csv_file):
    # Read the existing CSV into a DataFrame
    df = pd.read_csv(csv_file)

    # Flag to check if "unique_id" column was newly created
    newly_created = False

    # Check if "unique_id" column exists
    if "unique_id" not in df.columns:
        df["unique_id"] = None
        newly_created = True

    # Generate new UUID for rows that don't have one
    df.loc[df["unique_id"].isna(), "unique_id"] = [
        str(uuid.uuid4()) for _ in range(df["unique_id"].isna().sum())
    ]

    # Move 'unique_id' column to the first position if newly created
    if newly_created:
        col_order = ["unique_id"] + [col for col in df.columns if col != "unique_id"]
        df = df[col_order]

    # Write the updated DataFrame back to the same CSV file
    df.to_csv(csv_file, index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add unique IDs to a CSV file.")
    parser.add_argument("csv_file", type=str, help="Path to the CSV file")

    args = parser.parse_args()

    # To update your CSV file
    update_csv_with_uuid(args.csv_file)
