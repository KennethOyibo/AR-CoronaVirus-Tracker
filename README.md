

## Program Description
This is a a speech interface that will provide up-to-the-date information about the covid-19 virus. In order to achieve this I had to used the iOS SDK to create an Augumented Reality application. SceneKit, a library from the iOS SDK,  was used to develop and program different functionalities of the AR assistant that interfaces with a user. The AR assistant is a 3D character (a doctor) that was imported from Mixamo.com. In addition, the SpeechRecognizer library from the iOS SDK is used to transcribe live speech received from the microphone. This transcribed speech is displayed to the user on the bottom of the screen as they talk.

Furthermore, I created a google cloud function (server) to handle network calls to the Dialog flow fullfilment. Therefore, the user interface(UI) passes transcribed text as an input to the cloud function. The cloud fucntion is responsible for making an API call to dialog flow and receive an audio file as a response which is passed back to the UI. The reason for creating the cloud function was to handle the authentication of dialog flow without exposing the private key. Also, this is the recommended approach by Dialog flow to handle authentication.

The application enables any user to ask questions about the corona virus as specified in the assignment description. Once the application launches, the user can began asking their questions. If the user pauses for longer than 2 secs after asking a question, a request is made and a response is given back. After the response is given back, the user can ask another question and the same pattern repeats.

## Tools used to develop
Xcode
Dialog flow
Google Cloud Platform (GCP)
Mixamo


## Dependencies
None. There are no dependencies. However, since I am using the Augumented Realiy library of the iOS SDK. This program has to be ran on a physical iphone device with an iOS version > 13.0.  Any iphone 6 and above should be already running on iOS13.

## How to compile
Unzip the file and navigate to ARAnimation folder. Double click on the "ARAnimation.xcodeproj" file. This will open it up in Xcode. Build/compile the project using "Cmd + B". 

## How to Run
To run the project. Connect to a physical iphone (iOS version > 13.0). Any iphone 6 and above should be already running on iOS13. Then make sure that a development team is selected/added in "Signing and Capablities". You will need to sign into a apple account(This is free). Then click on Run (the play button). When application opens up on the iphone, accept the permision request.

## Deprecated
This project is not currently maintained and as such the code might break when ran. The link to a video demo is : https://youtu.be/y2L5hMHjaqE




