import base64
import email
import os
import re
import sys
import asyncio
import time

from bs4 import BeautifulSoup
from imapclient import IMAPClient, SocketTimeout

MAIL_DOMAIN = os.getenv("MAIL_DOMAIN")
MAIL_NAME = os.getenv("MAIL_NAME")
MAIL_PASSWD = os.getenv("MAIL_PASSWD")


def login():
    timeout = SocketTimeout(5, 60)
    client = IMAPClient(host="imap.{}".format(MAIL_DOMAIN), port=143, ssl=False, timeout=timeout)
    try:
        client.login("{}@{}".format(MAIL_NAME, MAIL_DOMAIN), MAIL_PASSWD)
        return client
    except client.Error as e:
        client.logout()
        print(e)
        sys.exit(1)


def get_all_message_id(client):
    client.select_folder('Inbox')
    return client.search(criteria='UNSEEN', charset='utf-8')


async def filter_need_delete_email(client, messages):
    async def fetch(message_id):
        return client.fetch([message_id], ['BODY[]'])  # 瓶颈, 不能并发访问

    delete_ids = set()
    for mid in messages:
        data = await fetch(mid)
        message = email.message_from_string(data[mid][b'BODY[]'].decode('utf-8'))
        try:
            subject_str = message.get('subject').replace("=?UTF-8?B?", "").replace("?=", "")
            subject = base64.decodebytes(bytes(subject_str, encoding="utf-8")).decode()
            if re.match(r"新增域名通知", subject) \
                    or re.match(r"删除域名通知", subject) \
                    or re.match(r"域名变更通知", subject) \
                    or re.match(r"服务更新通知", subject) \
                    or re.match(r"服务配置变更通知", subject) \
                    or re.match(r"服务配置版本变更通知", subject) \
                    or re.match(r"服务配置生效通知", subject) \
                    or re.match(r"服务版本变更通知", subject) \
                    or re.match(r"nginx配置下发通知", subject) \
                    or re.match(r"nginx配置变更通知", subject) \
                    or re.match(r"hosts变更通知", subject) \
                    or re.match(r"集群变更通知", subject) \
                    or re.match(r".*服务异常.*", subject):
                delete_ids.add(mid)
                continue
        except Exception:
            pass

        email_from = email.utils.parseaddr(message.get('from'))[1]
        if email_from == "no-reply@sns.amazonaws.com":
            delete_ids.add(mid)
            continue

        if email_from != "noreply@gitlab.{}".format(MAIL_DOMAIN):
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
                        or re.match(r"\s+nginx配置变更通知", text) \
                        or re.match(r"\s+hosts变更通知", text):
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
