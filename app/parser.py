import imaplib
import email
import base64
from bs4 import BeautifulSoup
import csv
from datetime import datetime

username='<INSERT_YOUR_EMAIL_HERE>' 
password='<INSERT_YOUR_PASSWORD_HERE>' 
imap_server = "imap.mail.ru"

imap = imaplib.IMAP4_SSL(imap_server)
imap.login(username, password) 
imap.select('INBOX/Receipts') 

# получаем id письма только от Перекрестка
def get_messageId()->list:
    try:
        sender="ofdreceipt@beeline.ru"
        sts,id_str=imap.search(None,'UNSEEN',f'FROM {sender}') 
    # полученный бинарный массив представим в виде обычного массива для последующего использования
        return id_str[0].decode('utf-8').split()
        
    except Exception as e: 
        print(f"Ошибка при получении messageId: {e}")
        return []  

#записываем html код в файл для последующего парсинга
def get_html(message_id):
    fetch_string_bytes = message_id.encode('utf-8')
    res,mail=imap.fetch(fetch_string_bytes,'(RFC822)')  
    email_message = email.message_from_bytes(mail[0][1])

    with open('email_body.txt', 'w', encoding='utf-8') as f:
        if email_message.is_multipart():
            for i in email_message.walk():
                if i.get_content_type() == 'text/html':
                    f.write(i.get_payload(decode=True).decode('utf-8')) 
        else:
            f.write(i.get_payload(decode=True)) 

#открывам каждое письмо и извлекаем необходимую информацию
def parser()->list:
    Products=[]
    with open ('email_body.txt') as file: 
        soup=BeautifulSoup(file,features="html.parser")
        #дата и время покупки
        w=soup.select('[style="width: 100%; font-size: 15px; line-height: 19px; color: #4a4a4a;"]')  
        date_time=w[0].select('td [align="right"]')[0].text.replace('\t', '').replace('\n', '').strip()
        D=date_time.replace(' | ',' ')
        
        #товары в чеке
        elements=soup.select('[style="color: #4a4a4a; font-size: 15px; width: 100%; line-height: 19px;"]')
        #информация о каждом товаре в  чеке
        
        for el in elements:
            l=[]
            l.append(el.select('[style="line-height: 21px; color: #000000; font-weight: bold;"]')[1].text.strip())
            l.append(el.select('td [align="right"]')[1].text.strip()) 
            l.append(el.select('td [align="right"]')[0].text.strip())
            l.append(datetime.strptime(D, "%d.%m.%Y %H:%M"))
            
            Products.append(l)
    return Products

def write_to_csv(file_name:str,Products:list):
    with open(f'{file_name}', mode='w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, delimiter=';')
    
        writer.writerow(['Name', 'Cost', 'Quantity','Date']) 
        writer.writerows(Products) 


Products=[]
id_mass=get_messageId()
for i in id_mass:
    get_html(i)
    Products.extend(parser())

write_to_csv('Products.csv')

