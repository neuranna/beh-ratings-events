import pandas as pd


def get_items_dict(even):
    df = pd.read_csv('sentences_EventsAdapt.csv')
    items = {'AI': [], 'AAN': [], 'AAR': []}
    active = df[df['Voice'] == 'Active']

    for idx, row in active.iterrows():
        if int(row['ItemNumber']) % 2 != even:
            continue
        condition = f'{row["Voice"]}-{row["Plausible/Implausible"]}'
        ev_type = row['EvType']
        if ev_type == 'AAR':
            condition += f'-{idx % 2 + 1}'
        if idx % 4 == 0:
            items[ev_type].append('')
        items[ev_type][-1] += f'# {row["EvType"]} {row["ItemNumber"]} {condition}\n' \
                              f'{row["Stimulus"]}\n'

    return items


def main():
    items = get_items_dict(even=True)
    trials_in_exp_num = 64

    with open('EventsAdapt.turk.csv') as csv:
        for _ in range(40):
            idx = {'AI': 0, 'AAN': 0, 'AAR': 0}
            with open('output.txt', 'w') as txt:
                for exp in 'AI', 'AAN', 'AAR':
                    for _ in range(trials_in_exp_num):
                        txt.write(items[exp][idx[exp]])
                        idx[exp] += 1
                        idx %= len(items[exp])
            # run turkolizer
            # add result to csv


if __name__ == '__main__':
    main()
