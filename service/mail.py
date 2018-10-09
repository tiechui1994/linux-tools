import email
import re
import sys
import asyncio
import time

from bs4 import BeautifulSoup
from imapclient import IMAPClient


def login():
    client = IMAPClient(host="imap.broadlink.com.cn", port=143, ssl=False)
    try:
        client.login("bao.qi@broadlink.com.cn", "0214.abc")
        return client
    except client.Error as e:
        client.logout()
        print(e)
        sys.exit(1)


def get_all_message_id(client):
    client.select_folder('Inbox')
    return client.search(criteria='ALL', charset='utf-8')


async def filter_need_delete_email(client, messages):
    delete_ids = set()
    for mid in messages:
        data = client.fetch([mid], ['BODY[]'])
        message = email.message_from_string(data[mid][b'BODY[]'].decode('utf-8'))
        if email.utils.parseaddr(message.get('from'))[1] != "noreply@gitlab.broadlink.com.cn":
            continue

        for part in message.walk():
            content_type = part.get_content_type()
            content = part.get_payload(decode=False)

            if content_type == "text/html":
                soup = BeautifulSoup(content, "html.parser")
                body = soup.find(name="body")
                if body is None:
                    continue

                text = body.get_text()
                if re.match(r"\s+新增域名通知", text) \
                        or re.match(r"\s+删除域名通知", text) \
                        or re.match(r"\s+服务配置变更通知", text) \
                        or re.match(r"\s+服务版本变更通知", text) \
                        or re.match(r"\s+服务配置生效通知", text) \
                        or re.match(r"\s+更新域名通知", text) \
                        or re.match(r"\s+nginx配置下发通知", text) \
                        or re.match(r"\s+nginx配置变更通知", text):
                    delete_ids.add(mid)

    return delete_ids


def delete_emails():
    client = login()
    message_ids = get_all_message_id(client)

    start = time.time()
    tasks = []
    step = len(message_ids) // 19
    for i in range(20):
        task = filter_need_delete_email(client, message_ids[i * step:(i + 1) * step])
        tasks.append(task)

    loop = asyncio.get_event_loop()
    dones, _ = loop.run_until_complete(asyncio.wait(tasks))

    delete_ids = set()
    for done in dones:
        delete_ids = delete_ids.union(done.result())

    client.delete_messages(delete_ids, silent=True)

    print("花费 %0.2f s 删除了 %d 封邮件" % (time.time() - start, len(delete_ids)))
    client.logout()


if __name__ == '__main__':
    delete_emails()
