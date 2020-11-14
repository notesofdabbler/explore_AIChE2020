
#
# Youtube help: https://www.youtube.com/channel/UC46vj6mN-6kZm5RYWWqebsg
#

from selenium import webdriver
import requests
from bs4 import BeautifulSoup
import pandas as pd
import time

driver = webdriver.Chrome()

driver.get("https://plan.core-apps.com/aiche2020/events?trackIds=94693210d53140b389648b84df76b433")
driver.maximize_window()

#------Get list of sessions and their links---------------

def get_sessions(driver):
    sessions_html = driver.execute_script("return document.body.innerHTML;")
    sessions_html2 = BeautifulSoup(sessions_html, 'html.parser')

    session_html3 =sessions_html2.find_all("a", {"class":"object-list-name"})
    sessionlist = [x.text for x in session_html3]
    sessionlinks = [x.get('href') for x in session_html3]
    
    return sessionlist, sessionlinks

sessioninfo1 = get_sessions(driver)
# manual scroll 1
sessioninfo2 = get_sessions(driver)
# manual scroll 2
sessioninfo3 = get_sessions(driver)
# manual scroll 3
sessioninfo4 = get_sessions(driver)
# manual scroll 4
sessioninfo5 = get_sessions(driver)
# manual_scroll 5
sessioninfo6 = get_sessions(driver)
# manual_scroll 6
sessioninfo7 = get_sessions(driver)
# manual_scroll 7
sessioninfo8 = get_sessions(driver)
# manual_scroll 8
sessioninfo9 = get_sessions(driver)


sessioninfos = [sessioninfo1, sessioninfo2, sessioninfo3, sessioninfo4, 
                sessioninfo5, sessioninfo6, sessioninfo7, sessioninfo8, sessioninfo9]

sessionlist = []
sessionlinks = []
for sessions in sessioninfos:
    sessionlist = sessionlist + sessions[0]
    sessionlinks = sessionlinks + sessions[1]
    
sessiondf = pd.DataFrame({'session': sessionlist, 'session_url': sessionlinks})
sessiondf = sessiondf.drop_duplicates()

sessiondf.to_csv('scraped_results/session.csv', index = False)

driver.close()

#--------Get list of talks and their links-----------------------------

driver = webdriver.Chrome()
driver.maximize_window()


sessiondf = pd.read_csv('scraped_results/session.csv')

session_url_list = sessiondf['session_url']
session_url_list = ['https://plan.core-apps.com' + x for x in session_url_list]

talksinfo = []

i = 0
for session_url in session_url_list:
    print(sessiondf['session'][i])
    driver.get(session_url)
    time.sleep(5.0)
    sessions_html = driver.execute_script("return document.body.innerHTML;")
    sessions_html2 = BeautifulSoup(sessions_html, 'html.parser')
    sessions_html3 = sessions_html2.find_all('div',{'class':'object-detail-inline-bookmark-link-container'})
    talksinfo.append(sessions_html3)
    time.sleep(2.0)
    i = i + 1
    
talksdfL = []    
    
for (i, session_talks) in enumerate(talksinfo):
    print(i)
    talktitle = [x.text for x in session_talks]
    talkurl = [x.find('a').get('href') for x in session_talks]
    talksdf_loc = pd.DataFrame({'title': talktitle, 'url': talkurl})
    talksdf_loc['session'] = sessiondf['session'][i]
    talksdf_loc['session_url'] = sessiondf['session_url'][i]
    talksdf_loc['sessionid'] = i
    talksdf_loc['talkid'] = list(range(len(talkurl)))
    talksdfL.append(talksdf_loc)
    
talksdf = pd.concat(talksdfL)

talksdf.to_csv('scraped_results/talks.csv', index = False)

#---------------Get authors and abstract for the talks-------------------------    
    
talksdf = pd.read_csv('scraped_results/talks.csv')

talkinfo_html = []

for i in range(talksdf.shape[0]):
    print(i)
    talkurl = 'https://plan.core-apps.com' + talksdf['url'][i]
    driver.get(talkurl)
    time.sleep(5.0)

    talk_html = driver.execute_script("return document.body.innerHTML;")
    talk_html2 = BeautifulSoup(talk_html, 'html.parser')
    
    talkinfo_html.append(talk_html2)
    time.sleep(2.0)
    
    
talkinfoL = []
absinfoL = []
    
for (i, talk_html2) in enumerate(talkinfo_html):
    
    print(i)

    affil_list = talk_html2.find_all("div", {"class":"line-three"})
    affil_list2 = [x.text for x in affil_list]

    author_list = talk_html2.find_all("div", {"class":"line-two"})
    author_list2 = [x.text for x in author_list]

    abstract = talk_html2.find_all("div", {"class": "subtree-mutation-observed"})
    if abstract[0].find("div"):
        abstract2 = abstract[0].find("div").get_text()
    else:
        abstract2 = ''

    talkinfodf_loc = pd.DataFrame({'author': author_list2, 'affil': affil_list2})
    talkinfodf_loc['sessionid'] = talksdf['sessionid'][i]
    talkinfodf_loc['talkid'] = talksdf['talkid'][i]

    absdf_loc = pd.DataFrame({'abstract': [abstract2]})
    absdf_loc['sessionid'] = talksdf['sessionid'][i]
    absdf_loc['talkid'] = talksdf['talkid'][i]
    
    talkinfoL.append(talkinfodf_loc)
    absinfoL.append(absdf_loc)
    
talkinfo_df = pd.concat(talkinfoL)
absinfo_df = pd.concat(absinfoL)

talkinfo_df.to_csv('scraped_results/talk_authors.csv', index = False)
absinfo_df.to_csv('scraped_results/talk_abstracts.csv', index = False)

driver.close()


