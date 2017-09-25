#Accessing Python Documentation

One of the ways to access python classes to read documenation on how they have been implemented is by using the built in python help function. I am going to take you through an example of using help to get more information an the python slackclient. 

This is a sample code. Here I am importing the ```SlackClient``` class from the ```slackclient```. Using the slackclient class to instantiate an object called ```my_slack_client```. See below

```python
#!/usr/local/bin/python
from slackclient import SlackClient

SLACK_BOT_TOKEN = 'xoxb-169813147714-sdafas-dont-use-this-tocken'
my_slack_client = SlackClient(SLACK_BOT_TOKEN)

my_slack_client.rtm_connect
```

But how did I know that rtm_connect() is a method of the slack client and I what it provides me. Well, hopefully there is good documenation on the internet, but another way to get that information 




Ok, so that is why you need good documentation. But what about classes that have poor documentation, well you could always read the source code. There are also some other functions that can potentially help to see methods and fields avaiable to you.

### 1. ```dir(myClass)``` This will list aout all attributes, methods ands fields in a tuple of myClass

``` python
print(dir(SlackClient))

['__class__', '__delattr__', '__dict__', '__doc__', '__format__', '__getattribute__', '__hash__', '__init__', '__module__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'api_call', 'append_user_agent', 'process_changes', 'rtm_connect', 'rtm_read', 'rtm_send_message']
[Finished in 1.482s]
```
### 2. ```myClass.__dict__``` This will print all the attributes, methods and fields of the in myClass in a dictionary

#### Running it against the class: prints attributes and their refrences in memory

```python
print(SlackClient.__dict__)

{'__module__': 'slackclient._client', 'api_call': <function api_call at 0x1032e4668>, 'rtm_send_message': <function rtm_send_message at 0x1032e4758>, 'rtm_read': <function rtm_read at 0x1032e46e0>, 'rtm_connect': <function rtm_connect at 0x1032e45f0>, 'append_user_agent': <function append_user_agent at 0x1032e4578>, '__dict__': <attribute '__dict__' of 'SlackClient' objects>, 'process_changes': <function process_changes at 0x1032e47d0>, '__weakref__': <attribute '__weakref__' of 'SlackClient' objects>, '__doc__': '\n    The SlackClient makes API Calls to the `Slack Web API <https://api.slack.com/web>`_ as well as\n    managing connections to the `Real-time Messaging API via websocket <https://api.slack.com/rtm>`_\n\n    It also manages some of the Client state for Channels that the associated token (User or Bot)\n    is associated with.\n\n    For more information, check out the `Slack API Docs <https://api.slack.com/>`_\n\n    Init:\n        :Args:\n            token (str): Your Slack Authentication token. You can find or generate a test token\n            `here <https://api.slack.com/docs/oauth-test-tokens>`_\n            Note: Be `careful with your token <https://api.slack.com/docs/oauth-safety>`_\n    ', '__init__': <function __init__ at 0x1032e4500>}
```

#### Running it against the instance of the class: prints the instantiated values of the attributes

```python
print(my_slack_client.__dict__)
{'token': 'xoxb-169813147714-sdafas-dont-use-this-tocken', 'server': username : None
domain : None
websocket : None
users : {}
login_data : None
api_requester : <slackclient._slackrequest.SlackRequest 
channels : []
token : xoxb-169813147714-sdafas-dont-use-this-t
connected : False
ws_url : None
}
```

### 3. ```help(myClass)``` my favorite, prints the methods avaiable in the class, including discriptions.

By calling the help function, we can see all the methods that we have available. In the example below, I can now see the ```rtm_connect``` method and the arguments that I have avaiable to me. So the help function seems to know alot about my classes, but where does its information from?  

1. Alot of the information from the python help function is generated automatically based on methods and fields declarations
2. Method details however are generated from comments that follow the docstring format (i.e. triple quotes, first-line after declaration).


```python
 #!/usr/local/bin/python
from slackclient import SlackClient

SLACK_BOT_TOKEN = 'xoxb-169813147714-sdafas-dont-use-this-tocken'
my_slack_client = SlackClient(SLACK_BOT_TOKEN)

print(help(SlackClient))


class SlackClient(__builtin__.object)
 |  The SlackClient makes API Calls to the `Slack Web API <https://api.slack.com/web>`_ as well as
 |  managing connections to the `Real-time Messaging API via websocket <https://api.slack.com/rtm>`_
 |  
 |  It also manages some of the Client state for Channels that the associated token (User or Bot)
 |  is associated with.
 |  
 |  For more information, check out the `Slack API Docs <https://api.slack.com/>`_
 |  
 |  Init:
 |      :Args:
 |          token (str): Your Slack Authentication token. You can find or generate a test token
 |          `here <https://api.slack.com/docs/oauth-test-tokens>`_
 |          Note: Be `careful with your token <https://api.slack.com/docs/oauth-safety>`_
 |  
 |  Methods defined here:
 |  
 |  __init__(self, token)
 |  
 |  api_call(self, method, timeout=None, **kwargs)
 |      Call the Slack Web API as documented here: https://api.slack.com/web
 |      
 |      :Args:
 |          method (str): The API Method to call. See
 |          `the full list here <https://api.slack.com/methods>`_
 |      :Kwargs:
 |          (optional) kwargs: any arguments passed here will be bundled and sent to the api
 |          requester as post_data and will be passed along to the API.
 |      
 |          Example::
 |      
 |              sc.server.api_call(
 |                  "channels.setPurpose",
 |                  channel="CABC12345",
 |                  purpose="Writing some code!"
 |              )
 |      
 |      :Returns:
 |          str -- returns the text of the HTTP response.
 |      
 |          Examples::
 |      
 |              u'{"ok":true,"purpose":"Testing bots"}'
 |              or
 |              u'{"ok":false,"error":"channel_not_found"}'
 |      
 |          See here for more information on responses: https://api.slack.com/web
 |  
 |  append_user_agent(self, name, version)
 |  
 |  process_changes(self, data)
 |      Internal method which processes RTM events and modifies the local data store
 |      accordingly.
 |      
 |      Stores new channels when joining a group (Multi-party DM), IM (DM) or channel.
 |      
 |      Stores user data on a team join event.
 |  
 |  rtm_connect(self)
 |      Connects to the RTM Websocket
 |      
 |      :Args:
 |          None
 |      
 |      :Returns:
 |          False on exceptions
 |  
 |  rtm_read(self)
 |      Reads from the RTM Websocket stream then calls `self.process_changes(item)` for each line
 |      in the returned data.
 |      
 |      Multiple events may be returned, always returns a list [], which is empty if there are no
 |      incoming messages.
 |      
 |      :Args:
 |          None
 |      
 |      :Returns:
 |          data (json) - The server response. For example::
 |      
 |              [{u'presence': u'active', u'type': u'presence_change', u'user': u'UABC1234'}]
 |      
 |      :Raises:
 |          SlackNotConnected if self.server is not defined.
 |  
 |  rtm_send_message(self, channel, message, thread=None, reply_broadcast=None)
 |      Sends a message to a given channel.
 |      
 |      :Args:
 |          channel (str) - the string identifier for a channel or channel name (e.g. 'C1234ABC',
 |          'bot-test' or '#bot-test')
 |          message (message) - the string you'd like to send to the channel
 |          thread (str or None) - the parent message ID, if sending to a
 |              thread
 |          reply_broadcast (bool) - if messaging a thread, whether to
 |              also send the message back to the channel
 |      
 |      :Returns:
 |          None
 |  
 |  ----------------------------------------------------------------------
 |  Data descriptors defined here:
 |  
 |  __dict__
 |      dictionary for instance variables (if defined)
 |  
 |  __weakref__
 |      list of weak references to the object (if defined)

None
[Finished in 0.146s]

```

So there you go, how to get information from classes


: