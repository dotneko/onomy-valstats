import pandas as pd
import os

from typing import List

def get_address(moniker :str) -> str:
    """
    Returns valoper address for validator moniker
    """
    for validator in [v for v in vals if v['moniker'] == moniker]:
        return validator['address']

def compute_delegations(moniker: str) -> (int, float):
    """
    Computes delegation statistics
    Returns delegation count and amount in NOM
    """
    header_row = ['delegate', 'amount']
    valoper_csv = get_address(moniker)[5:] + "_dlgs.csv"
    try:
        valoper_delegates = pd.read_csv(valoper_csv, header=None, names=header_row)
    except Exception:
        # Skip missing csv
        return (0, 0, 0)
    # Convert amount to float (int too large)
    valoper_delegates['amount'] = valoper_delegates['amount'].astype(float)
    # Sort descending by amount, show top largest delegates
    df = valoper_delegates.sort_values(['amount'], ascending=[False])
    # Generate readable amount format based on 18 decimal places
    df['nom'] = df['amount'] / 10**18
    df.nlargest(n=10, columns=['amount'])
    num_delegations = df['delegate'].count()
    if num_delegations == 0:
        return (0, 0, 0)
    nom_delegated = df['nom'].sum()
    print(
    f"""{moniker}\n{'='*len(moniker)}
- {get_address(moniker)}
- Total Delegations   : {num_delegations}
- Total NOM delegated : {nom_delegated}\n---\n""")
    if num_delegations > 0:
        top10df = df.nlargest(n=10, columns=['amount'])
        # Compute proportion from top 10 delegators
        top10pc = top10df['nom'].sum() / nom_delegated
        print(f"Top 10 delegators (Share of delegations: {top10pc*100:.4}%)\n---")
        #print(top10df,"\n----")
    else:
        top10pc = 0
    return (num_delegations, nom_delegated, top10pc)

if __name__ == "__main__":
    cwd = os.getcwd()
    validators_csv :str = "validators.csv"
    delegate_csvs :List[str] = [f for f in os.listdir(cwd) if f.startswith("valoper") and f.endswith(".csv")]
    xcva : List[str] = ['nomblocks.io', 'lila.holdings', 'NCC', 'NomAddict-JP']

    # Read validators
    _header_row : List[str]=['moniker', 'address']
    vals = pd.read_csv(validators_csv, header=None, names=_header_row).to_dict('records')

    # Compute delegation statistics
    for validator in vals.copy():
        (num, nom, top10pc) = compute_delegations(validator['moniker'])
        if num == 0:
            # Remove validator with empty delegations
            print(f"Skipping validator {validator['moniker']}: empty delegations\n---")
            vals.remove(validator)
        else:
            validator['delegators'] = num
            validator['total'] = nom
            validator['top10pc'] = top10pc * 100
            if validator['moniker'] in xcva:
                validator['xcva'] = True
            else:
                validator['xcva'] = False

    # Convert to dataframe, sort and compute percentages
    df = pd.DataFrame.from_dict(vals)
    df['pc'] = df['total'] / df['total'].sum() * 100
    df = df.sort_values(['pc'], ascending=[False])

    # Calculate share by XCVA
    xcva_total : float = df.loc[df['xcva'] == True, 'total'].sum()
    xcva_pc : float = xcva_total / df['total'].sum() * 100

    # Display summary
    print("Validator Summary Statistics")
    print("============================")
    print(df[['moniker', 'address', 'delegators', 'pc', 'total', 'top10pc']].round(2))
    print("============================")
    print(f"XCVA share: {xcva_pc:.4}%\n---\n")
    
