import os
from dotenv import load_dotenv
import json
import requests
import pandas as pd
import progressbar

load_dotenv()
API_KEY = os.getenv('API_KEY')


def find_all_indices_of(value, list_to_search):
    results = list()
    for i, list_value in enumerate(list_to_search):
        if type(value) is list:
            if list_value in value:
                results.append(i)
        else:
            if list_value == value:
                results.append(i)
    return results


def multi_index(list_to_index, indices):
    return [element for i, element in enumerate(list_to_index) if i in indices]


wb_climate_sector_map = {
    "000081": "Climate change",
    "000811": "Climate mitigation",
    "000812": "Climate adaptation"
}


def main():
    # Use the IATI Datastore API to fetch all titles for a given publisher
    rows = 1000
    next_cursor_mark = '*'
    current_cursor_mark = ''
    results = []
    with progressbar.ProgressBar(max_value=1) as bar:
        while next_cursor_mark != current_cursor_mark:
            url = (
                'https://api.iatistandard.org/datastore/activity/select'
                '?q=(reporting_org_ref:"44000" AND sector_vocabulary:"98")'
                '&sort=id asc'
                '&wt=json&fl=iati_identifier,sector_code,sector_percentage,sector_vocabulary,'
                'title_narrative,description_narrative'
                '&rows={}&cursorMark={}'
            ).format(rows, next_cursor_mark)
            api_json_str = requests.get(url, headers={'Ocp-Apim-Subscription-Key': API_KEY}).content
            api_content = json.loads(api_json_str)
            if bar.max_value == 1:
                bar.max_value = api_content['response']['numFound']
            activities = api_content['response']['docs']
            len_results = len(activities)
            current_cursor_mark = next_cursor_mark
            next_cursor_mark = api_content['nextCursorMark']
            for activity in activities:
                results_dict = dict()
                results_dict['iati_identifier'] = activity['iati_identifier']
                results_dict['text'] = ' '.join(activity.get('title_narrative', []) + activity.get('description_narrative', []))
                reporting_org_v2_indices = find_all_indices_of('98', activity['sector_vocabulary'])
                reporting_org_sector_codes = multi_index(activity['sector_code'], reporting_org_v2_indices)
                reporting_org_sector_percentages = multi_index(activity['sector_percentage'], reporting_org_v2_indices)
                for wb_climate_sector_code in list(wb_climate_sector_map.keys()):
                    split_dict = results_dict.copy()
                    split_dict['wb_sector_name'] = wb_climate_sector_map[wb_climate_sector_code]
                    if wb_climate_sector_code not in reporting_org_sector_codes:
                        wb_sector_percentage = 0
                    else:
                        wb_sector_index = reporting_org_sector_codes.index(wb_climate_sector_code)
                        wb_sector_percentage = float(reporting_org_sector_percentages[wb_sector_index]) / 100
                    wb_sector_percentage = min(wb_sector_percentage, 1)
                    split_dict['wb_sector_percentage'] = wb_sector_percentage
                    results.append(split_dict)
                    
            if bar.value + len_results <= bar.max_value:
                bar.update(bar.value + len_results)
    
    # Collate into Pandas dataframe
    df = pd.DataFrame.from_records(results)

    # Write to disk
    df.to_csv(
        os.path.join('input', 'world_bank_climate_percentages.csv'),
        index=False,
    )


if __name__ == '__main__':
    main()