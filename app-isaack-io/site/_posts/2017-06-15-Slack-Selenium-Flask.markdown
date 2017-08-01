---
layout: post
title: "SlackBots, Selenium, MongoDB and Flask"
excerpt: "Selenium is mainly used for doing automated website testing. I wanted to use slack to automate tasks I need to do for my day to day work, so what better way to accomplish that, puppet selenium using a slackbot "
categories: [Slack Bot, Chatbots, Selenium, MongoDB]
---

# Why Do all this?

Selenium is mainly used for automated website testing. It works well especially in CI/CD when using a tool like Jenkins during functional testing. You can also use Selenium to do almost anything that invloves browser automation. I had a specific need to automate tasks that I perform at my workplace Content Management System (CMS) and I was planning to build a slackbot to help me accomplish this, so Selenium became my new best friend. 

# Tools of the trade

I needed the following compomonents to build the Bot. 


[The following github repo has all the content to make this work](https://github.com/mugithi/slackbot-selenium-flask-s)

***My workplace CMS***

This is a home grown asp.net application. It works really well and it is what keeps the lights on at my current employer. Think of it like Salesforce but much better. It has an automated task management system that I have to interact with on a day to day basis. I took the process of creating, updating and deleting tasks and converted it into a Selenium workflow.

Granted, it would have been easier for me to request access to the MySQL database to read and write directly to the DB, but you never learn doing the same o same o. Also, I did want to build a template that I could use with any website to automate tasks.

***Selenium***

As I mentioned, I used this to perform all the CMS automation. This included loging in using my AD credentials, navigating to the task page, grabing all tasks assigned to me. Accepting any or specific pending tasks with comments on task status


***MongoDB***

Because Selenium was essentialy navigating a dymanic website, there was significant latency as SQL queries were performed against the DB and the pages rendered and delivered by the asp.net application. In order for me to speed the return of the data to the SlackBot, I used a MongoDB database essentially to cache my data for all slackbot read requests. I also wanted to reduce the load on the producion SQL database.

***Flask***

In my quest to use all things Python, I was runnnig a flask api server. Every Slackbot call was translated to an API call to my flask api server and various Selenium methods were executed. The flask HTTP 200 POST was an encoded64 data payload json object read from the MongoDB database. 

***SlackBot***

This made api calls to the flask server and decoded the returned JSON object. It then had the responsibility of unpacking the json, formating it and sending it to slack.com using an api token. 

Here is sample of the slackbot

<iframe src="https://pastebin.com/embed_iframe/JgC0P92R" style="border:none;width:100%"></iframe>

#Worklow
 
- From slackbot, user issues refresh of tasks: Selenium grabs the data from the asp.net website and stores it in the mongodb database, JSON is sent to slackbot that relays it to the Slack client
- From slackbot, user performs queries of tasks pending, accepted, sorting on due vs overdue. All requests come MongoDB database
- From slackbot, user performs any task changs, all requests go through selenium and finaly refresh of tasks and database update.

Shown by this diagram

![](https://github.com/mugithi/slackbot-selenium-flask-s/blob/master/SLACK-APP.png?raw=true)


###Deployment 
**Docker EE, Terraform and Ansible**

Since all my components were containerised, I needed a place to run this and I chose to use Docker EE. I deployed this using terraform to my vsphere Environemt. [You can find the terraform and ansible in this Github repository](https://github.com/mugithi/terraform-build/tree/master/multiple-instance-esx)


