#### Table of Contents

1. **Main GUI**
    1. Loading Files
    2. Exporting Files
2. **Volume Processing**
    1. Interface Guide
    2. Developer Mode
3. **Neuron Segmentation**
    1. Interface Guide
    2. [Documentation](https://yemini-lab.github.io/NeuroPAL_ID/docs/)
4. **Neuronal ID**
    1. Interface Guide
    2. References
    3. Images & Datasets
5. **Video Tracking & Tracing**
	1. Interface Guide
	2. Sample W

#### Main GUI

The main NeuroPAL GUI is the window that will appear when you open `visualize_light.mlapp` or run our compiled executable file. Though complex, we've written up a quick guide to help you find your way around below:

![GUI](https://i.imgur.com/OxrAu1i.png)

|Label|Description|
|:-:|:-|
|**x**|Z-stacks of the NeuroPAL image and neuron labels. Green dots indicate named neurons, red dots unnamed ones.|
|**y**|The maximum intensity projection of the entire image.|
|**z**|This slider allows you to move through different z-stacks.|
|||
|**a**|This is NeuroPAL's main menu. From left to right, it contains the `File` menu, the pre-processing menu (where you can downsample or adjust the threshold), the `Image` menu (where you can manipulate the image and adjust its gamma or histogram), the `Neurons` menu (where you can import neurons and perform batch actions), the `Display` menu (where you can adjust what information NeuroPAL displays), the `Analysis` menu (where you can save your work), and a `Help` menu with convenient links.|
|**b**|This is the metadata menu. From left to right, you can open a NeuroPAL image, save your work, and view and edit metadata related to the worm you're currently viewing, such as the body part on display, the worm's age, its sex, its strain, and any additional notes.|
|**c**|This is the ID menu. From left to right, you can begin auto-IDing, you can define the details of your manual ID, and you can change what happens if you click anywhere on x.|
|||
|**d**|Here you can select the color channels NeuroPAL_ID uses to visualize its images.|
|**e**|If you're using our (as yet WIP) auto-identification function, this space is where you can designate the specific method you'd like the program to use. You'll also see a list of neurons the program believes to be nearby as well as an indication of how confident it is in its ID.|
|**f**|This is where you can easily navigate various ganglia and browse lists of neurons you've identified as well as neurons that should exist in the selected region but that have yet to be ID'd. |

#### Image Manipulation

The `Image` sub-menu in NeuroPAL's main menu ("a" in the main GUI) contains a number of options. If you select "Adjust Histogram", a separate window will pop up in which you can adjust the luminosity of individual channels with the guidance of a histogram. Below is a quick guide to that window.

![Hist](https://i.imgur.com/MkPPw8P.png)

|Label|Description|
|:-:|:-|
|**x**|Maximum intensity projection of your NeuroPAL image.|
|**y**|A (Pixel Number x Pixel Intensity) histogram of all visible channels.|
|**z**|A tab group displaying the individual channel gammas and their curves.|
|||
|**a**|This is a list of all currently supported channels. Checking a channel will render it both in the image and in all plots.|
|**b**|This is the min/max menu. Here you can define the minimum and maximum intensities represented in any given channel.|
|**c**|Clicking on a given channel's lock toggle will prevent it from being edited.|
|**d**|Clicking on a given channel's reset button will restore it to what it was before the histogram window was opened.|
|**e**|This is the settings menu. Here you can adjust the gamma across all channels, save your histogram in a guide file, and load and display saved guide files.|

#### Neuron Segmentation

The `Neurons` sub-menu in NeuroPAL's main menu ("a" in the main GUI) contains a number of options. If you select "Auto Segmentation", a separate window will pop up allowing you to segment the image and obtain a list of automatically detected neuron centers. Below is a quick guide to that window.

![Hist](https://i.imgur.com/iQ7lv0y.png)

|Label|Description|
|:-:|:-|
|**x**|By default, a maximum intensity projection of your NeuroPAL image. Can also be set to display a particular z-slice.|
|**y**|A slider allowing you to browse specific z-slices.|
|||
|**a**|This panel features 3 sub-menus: "Neuron", which displays information on neurons post-segmentation (unpopulated by default) and allows users to either export neuron centers or pass them back into the main NeuroPAL_ID window, "Image", which allows you to select a specific range of slices to segment or to switch back to the maximum projection, and "Credit", which features information regarding the origins of the particular segmentation module being used.|
|**b**|This panel features the core controls of the auto-segmentation window. The black out tool allows you to zero out specific sections of the image (such as the gut) to minimize false positives. The histogram tool will open the histogram window described earlier. The "Generate" button starts the segmentation process and the "Reset" button undoes all changes made to the image since the window was opened.|
|**c**|This panel allows users to edit the parameters of the segmentation process. Hovering over each label will show information regarding what each parameter means.|
|**d**|These panels allow users to change some of the segmentation settings. By default, the noise filter level is calculated automatically using the 95th percentile of pixels, but it can also be set manually. The cell filter specifies the measure by which all detected segments are filtered -- either by the minimum size (in microns) or by the neuron count (in which case only the n biggest segments are kept).|

#### Working with NWB Files

**NeuroPAL_ID** natively supports loading, viewing, editing, and saving data in the [NWB](https://www.nwb.org/nwb-neurophysiology/) format using the [ndx-multichannel-volume](https://github.com/focolab/ndx-multichannel-volume/tree/main) extension. Future software expansions will build on this support as well.

Click on each of the previews below to view them in full resolution.


#### Loading Activity

![NWB_Activity](https://imgur.com/wGXsSCT.gif)


#### Loading Video

![NWB_Video](https://imgur.com/9PWTw6u.gif)

#### Saving NWB Files

![NWB_Save](https://imgur.com/rGbQOPQ.gif)

#### Technical Details

#### Class, Package, and Usecase Diagrams

> To build a fast and scalable system we followed object oriented design practices. We identified internally coherent and externally independent classes in our environment and established their properties and behavior, as well as their interactions with other modules. We have separate packages for data handling, methods, logging, biological objects, and user interface. Each of these packages contains relevant classes and the functionalities of the system is built upon the interactions between the classes. For reusability purposes we tried to develop a modular system with independent modules. This allows the users of the system to reuse different compartments of the system for other purposes.

> ![Class](https://dl.dropboxusercontent.com/s/ngtlg5q4k7vlqcs/Class.png)

> ![Package](https://dl.dropboxusercontent.com/s/6en1q28tfdze7h9/Package.png)

> ![Usecase](https://dl.dropboxusercontent.com/s/xmapjhtnlfylozz/Usecase.png)