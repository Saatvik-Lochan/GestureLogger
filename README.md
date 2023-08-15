# GestureLogger
## Purpose
This application has been built to make the creation of
hand-gesture datasets easier. It facilitates the asynchronous 
setup, capture, annotation and export of this data, 
with the use of [WebXR](https://developer.mozilla.org/en-US/docs/Web/API/WebXR_Device_API)
enabled VR headsets as the capture device.

Modern VR headsets have the ability to record the hand-skeletal
data of the user. This tool harnesses that capability to make capturing
hand data easy. Simply:
 - Define your gesture classes (clap, grip, etc.)
 - Create trials which include multiple gestures
 - Push trials to specific participants on the server
 - Asynchronously download these trials from the server after
 the participant has performed them on their VR headset
 - Annotate the captured data in batches
 - Export the captured data to a dataset

## Installation
You can install and run a version of this app through the standalone
installer: [unimplemented link]()

You can also run this by cloning the repository  
```console
$ git clone https://github.com/Saatvik-Lochan/GestureLogger.git
```
and opening [`Login.mlapp`](Login.mlapp) with [MATLAB](https://uk.mathworks.com/products/matlab.html).

## Usage
The usage of this application is split into three main parts:
 - [Setup the project](#setup)
 - [Capture the data](#capture)
 - [Annotate and export](#annotate-and-export)


### ⚠️ Hosting servers
It is recommended that you host your own servers (see 
[WebGestureCapture](https://github.com/Saatvik-Lochan/WebGestureCapture.git) 
and [WebGestureCaptureBackend](https://github.com/Saatvik-Lochan/WebGestureCaptureBackend.git)
for instructions on how to host).

**TODO - add instructions for changing server url**

> There is no guarantee that the default servers will be able to serve 
your requests. Though you are welcome to use the default servers to 
trial the software. 

### Setup
#### Register and Login
On opening the application you will first have to register your project
with the server. 

You can then login by selecting the `.json` project file with the name
of the project you registered last time

> If the server does not respond, you might have to host your own 
[server](#⚠️-hosting-servers).

#### Creating Gesture Classes
![UML of the annotation gesture classes](docs/annotation_uml.png)
*Outline of the relationship between annotations*

You can create multiple `gesture classes`. Each is coupled to an `annotation`.
An `annotation` can either be `continuous` or `discrete`. 

A `discrete` annotation  has a single integer value `triggerFrame` while a 
`continuous` annotation has a beginning, `startFrame`, and an end, `endFrame`.

`continuous` annotations can have children called `sub-annotations`, which
are functionally the same as `annotations` but can not be coupled to a
`gesture class`.

You can create new `gesture classes` by clicking `Add Gesture`. You 
can edit the annotation coupled with it in the right hand pane - adding
`sub-annotations`, changing the type, the name, etc.

![A screenshot of the Edit Gesture panel](docs/edit_gesture.png)

The predicted properties tab is optional, and will be used
to populate the default annotation values.

#### Creating Trial Templates
A `trial` is the unit of data capture from the perspective of the
application. You must put gestures in a `trial template` before
you can send them to the VR headset for data capture. 

It consists of multiple `gesture classes` in a
particular order. Each `gesture class` is mapped to 
 - an instruction - *text which is displayed before a participant
 must perform a gesture*
 - a duration - *the duration in seconds that the participant's 
 hands must be recorded for*
 - a number of repetitions - *the number of times this `gesture 
 class` must be repeated*

these dictate how the trial will be displayed to the user during
the VR experience. 

A `trial template` also includes some trial-level properties, such
as a name and a trial-level instruction (which will be displayed
before any of the gestures).

![Screenshot of the trial template tab](docs/trial_template.png)

> None of the instruction text has word-wrap or auto-sizing, you
might want to test that the text looks alright before you use the
trial in a project.

#### Adding Participants and Pushing Trials
Now that you have some `trial templates` set up, you can add 
`participants` and then push `trials` onto them - this works in
two parts:
1. First create a participant, and add a `trial` to it
![Screenshot of an unpushed trial](docs/unpushed_trial.png)
2. Sync the project with the server to push the `trial` to the server
![Screenshot of a pushed trial](docs/pushed_trial.png)

> The sync button is in the menu bar at the top left of the app 

You may also add any useful information about a participant 
(such as an email, or a name) in a text box located under the `Participant Data` tab.

### Capture
The project has now been set up and the data capture can start.
This works as follows:
1. [Get a URL from the application](#getting-the-url) 
2. [Open the URL on the VR Headset](#opening-the-url-on-the-vr-headset)
3. [Make the participant perform the trial](#making-the-participant-perform-the-trial)
4. [Download the captured data from the server](#downloading-the-captured-data)

#### Getting the URL
Each participant will have their own URL. This URL will not change,
and they will be able to access any pending trials (i.e. trials
which have been pushed but not completed) through this URL.

![Screenshot of where to find the URL](docs/participant_url.png)

#### Opening the URL on the VR Headset
This URL must now make its way to a VR Headset. The only requirement
on this headset is that it must have a [WebXR](https://developer.mozilla.org/en-US/docs/Web/API/WebXR_Device_API)
enabled browswer. A few common headsets which support this are:
- Quest
- Hololens
- Magic Leap One
- ARCore devices

And so on - a more complete list can be found [here](https://immersive-web.github.io/webxr/explainer.html#target-hardware).  

> How you move the URL to the headset is up to you, however we 
recommend you bookmark this URL on the headset's browser.

#### Making the participant perform the trial
The participant must open the URL, and click `Enter VR` and 
follow the instructions to perform the `trial`.

> We recommend you show them [this]() video (or a similar one) so 
they are not confused

Once done, they are prompted to remove the headset. The trial
can be performed anywhere, and at anytime, as long as they
have the headset. This allows for en-masse collection of data
once participants have gotten the hang of recording gestures.

#### Downloading the captured data
This is as simple as clicking the `Sync` button in the menu bar.
The data can be downloaded from the server for up to 3 days after it 
was recorded. This time can be changed or removed entirely if you 
decide to [host your own servers](#⚠️-hosting-servers). 

### Annotate and Export
This involves a few steps:
1. Finding the gesture to annotate
2. Annotating the gesture
3. Marking the gesture for export
4. Exporting the dataset

#### Finding the right gesture
Downloaded gesture can be found in three major ways:
- By `gesture class` - *navigate to the `Gestures` tab then `Gesture 
 Instances`*
- By `participant` - *navigate to the `Participants` tab then `Performed Gestures`*
- By annotation status - *navigate to the `Captures` tab*

#### Annotating the gesture
Select the `gesture instance` in the table, and then select `Open
Gesture Annotator`. You may have to wait for the new application to open.





### Useful notes

## Extension
To add functionality, you must have access to [MATLAB AppDesigner](https://uk.mathworks.com/products/matlab/app-designer.html). Then
you can simply open [`Login.mlapp`](Login.mlapp) to start.

You can run a development session from within MATLAB, and you
can build a standalone application with the [Application Compiler](https://uk.mathworks.com/help/compiler/applicationcompiler-app.html).