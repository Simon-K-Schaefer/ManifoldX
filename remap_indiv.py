import pandas as pd
from Bio import PDB
import argparse
import os

def parse_pdb_residues(pdb_file):
    """Extracts residue mapping from a PDB file, preserving insertion codes."""
    parser = PDB.PDBParser(QUIET=True)
    structure = parser.get_structure("protein", pdb_file)

    residue_map = {}  # {(chain, renumbered_pos): original_res_number}

    for model in structure:
        for chain in model:
            chain_id = chain.id  # Chain identifier (e.g., "A")
            residue_map[chain_id] = []  # Initialize list for this chain

            for i, res in enumerate(chain, start=1):  # Renumber starting from 1
                if res.id[0] == " ":  # Exclude heteroatoms/water
                    original_res_num = str(res.id[1]) + (res.id[2].strip() if res.id[2] != " " else "")
                    residue_map[chain_id].append(original_res_num)  # Preserve insertion codes

    return residue_map

def map_residues(table_file, pdb_file):
    """Maps renumbered sequence positions to original residue numbers and renames output file."""
    
    # Determine file format based on extension
    file_extension = os.path.splitext(table_file)[1].lower()
    
    if file_extension == ".tsv":
        sep = "\t"
    elif file_extension == ".csv":
        sep = ","
    else:
        raise ValueError("Unsupported file format. Use a TSV or CSV file.")
    
    # Load the table with the correct separator
    df = pd.read_csv(table_file, sep=sep)

    # Normalize column names (lowercase)
    df.columns = df.columns.str.lower()

    # Ensure required columns exist
    required_columns = {"chain", "pos", "res"}
    if not required_columns.issubset(df.columns):
        raise ValueError(f"Table must contain columns: {required_columns}, but found: {set(df.columns)}")

    pdb_mapping = parse_pdb_residues(pdb_file)

    # Function to get original residue number (including insertion codes)
    def get_original_res(chain, pos):
        if chain in pdb_mapping and 0 < pos <= len(pdb_mapping[chain]):
            return pdb_mapping[chain][pos - 1]  # Convert 1-based pos index
        return None  # No mapping found

    # Apply mapping
    df["orn"] = df.apply(lambda row: get_original_res(row["chain"], row["pos"]), axis=1)

    # Generate output file name with PDB prefix
    pdb_base_name = os.path.splitext(os.path.basename(pdb_file))[0]  # Get PDB filename without extension
    table_base_name, table_ext = os.path.splitext(os.path.basename(table_file))  # Get table filename

    output_file = f"{pdb_base_name}_{table_base_name}_with_orn{table_ext}"

    # Save updated table with the correct separator
    df.to_csv(output_file, sep=sep, index=False)
    print(f"Updated table saved as: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Map renumbered residues to original PDB numbering (including insertion codes)")
    parser.add_argument("table", help="Input CSV/TSV table with 'Chain', 'Pos', and 'Res' columns")
    parser.add_argument("pdb", help="Input PDB file")
    args = parser.parse_args()

    map_residues(args.table, args.pdb)
