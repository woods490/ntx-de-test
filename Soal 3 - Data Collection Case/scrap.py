import os
import json
import httpx
from bs4 import BeautifulSoup
import pandas as pd
from tqdm import tqdm
from httpx import HTTPError

BASE_URL = "https://www.fortiguard.com/encyclopedia?type=ips&risk={level}&page={i}"
OUTPUT_DIR = "datasets"


async def fetch_data(level, page):
    url = BASE_URL.format(level=level, i=page)
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            response.raise_for_status()
            return response.text
        except HTTPError as e:
            print(f"Error fetching data for level {level}, page {page}: {e}")
            return None


def parse_data(html):
    soup = BeautifulSoup(html, "html.parser")
    entries = []
    base_url = 'https://www.fortiguard.com'
    for div in soup.find_all('div', class_='row'):
        link = div.get('onclick')
        title_div = div.find_next('div', class_='col-lg', style='word-break:break-all')

        if link and title_div:
            link = base_url + link.split('=')[-1].strip().strip("';")
            title = title_div.select_one('b').get_text(strip=True) if title_div.select_one('b') else None

            entries.append({'title': title, 'link': link})

    return entries


async def scrape_level(level):
    output_file = os.path.join(OUTPUT_DIR, f"forti_lists_{level}.csv")
    skipped_pages = []
    max_pages = {1:13, 2:56, 3:197, 4:421, 5:271}

    for page in tqdm(range(1, max_pages[level]+1)): 
        html = await fetch_data(level, page)

        if html is not None:
            entries = parse_data(html)
            if entries:
                if page == 1:
                    pd.DataFrame(entries).to_csv(output_file, index=False)
                else:
                    pd.DataFrame(entries).to_csv(output_file, mode="a", header=False, index=False)
            else:
                skipped_pages.append(page)
        else:
            skipped_pages.append(page)

    return skipped_pages

async def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    skipped_data = {}

    for level in range(1, 6):
        print(f"Scraping data for level {level}")
        skipped_pages = await scrape_level(level)

        if skipped_pages:
            skipped_data[f"Level {level}"] = skipped_pages

    if skipped_data:
        with open(os.path.join(OUTPUT_DIR, "skipped.json"), "w") as json_file:
            json.dump(skipped_data, json_file, indent=2)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())