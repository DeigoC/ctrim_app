# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, messaging

initialize_app()
options.set_global_options(max_instances=10, region='europe-west1')

@https_fn.on_call(region='europe-west1')
def send_notification_to_multiple_tokens(req: https_fn.CallableRequest) -> any:
    # title = req.data['Title']
    # body = req.data['Body']
    # tokens = req.data['Tokens']
    # data = req.data['Data']
    if (str(req.data['Tokens']).find(',') != -1 ):    
        tokens = str(req.data['Tokens']).split(',')
    else:
        tokens = [str(req.data['Tokens'])]
   
    dataDict = {};

    iosImage = str(req.data['iOSImage'])
    androidImage = str(req.data['AndroidImage'])

    if (str(req.data['DataKeys']).find(',') != -1 ):   
        dataKeys = str(req.data['DataKeys']).split(',')
        dataValues = str(req.data['DataValues']).split(',')
        for i in range(len(dataKeys)):
            dataDict[dataKeys[i]] = dataValues[i]
    else:
        dataDict = {str(req.data['DataKeys']) : str(req.data['DataValues'])}

    print('--------------- Tokens are ' + str(tokens))
    print('--------------- DataDict is ' + str(dataDict))
    msg = messaging.MulticastMessage(
        tokens=tokens,
        data=dataDict,
        notification=messaging.Notification(
            title=req.data['Title'],
            body=req.data['Body']
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(mutable_content=True)),
            fcm_options=messaging.APNSFCMOptions(image=iosImage)
        ),
        android=messaging.AndroidConfig(notification=messaging.AndroidNotification(image=androidImage))
    )

    messaging.send_multicast(msg)
    return {'result':'finished sending to multiple devices!'}

@https_fn.on_call(region='europe-west1')
def send_to_topic(req: https_fn.CallableRequest) -> any:
    topic = str(req.data['Topic'])
    dataDict = {};
    iosImage = str(req.data['iOSImage'])
    androidImage = str(req.data['AndroidImage'])

    if (str(req.data['DataKeys']).find(',') != -1 ):   
        dataKeys = str(req.data['DataKeys']).split(',')
        dataValues = str(req.data['DataValues']).split(',')
        for i in range(len(dataKeys)):
            dataDict[dataKeys[i]] = dataValues[i]
    else:
        dataDict = {str(req.data['DataKeys']) : str(req.data['DataValues'])}

    print('--------------- Topic is ' + topic)
    print('--------------- DataDict is ' + str(dataDict))
    
    msg = messaging.Message(
        topic=topic,
        data=dataDict,
        notification=messaging.Notification(
            title=req.data['Title'],
            body=req.data['Body']
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(mutable_content=True)),
            fcm_options=messaging.APNSFCMOptions(image=iosImage)
        ),
        android=messaging.AndroidConfig(notification=messaging.AndroidNotification(image=androidImage))
    )

    messaging.send(msg)
    return {'result':'finished sending to topic!'}

@https_fn.on_call(region='europe-west1')
def hello_world(req: https_fn.CallableRequest) -> any:
    print('Hello there! Here is the Request data: ' + str(req.data))
    return{'result':'finished hello world!'}