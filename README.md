<a id="readme-top"></a>
<!--
*** Thanks for checking out the FluoSimUI Readme. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** 
*** I imagine a world where scientific knowledge provides solutions for every health challenge, enabling everyone to live with autonomy, freedom, and well-being.
*** I created this project so that I might streamline taking raw microscopy data in my PhD and convert that in biological insights that might aid understanding the next generation of engineered T cell immunotherapies.
*** I hope this could be useful to a few future scienctist in whatever pursuit they are taking on. 
*** I would be overjoyed to help enable you to make discoveries and share knowlegde with humanity.
-->

<!-- PROJECT LOGO --> <br /> <div align="center">   <a href="https://github.com/kscrudders/FluoSimUI"> <img src="/FluoSimUI_projectlogo.png" alt="Logo" width="402" height="300"> </a> <h3 align="center">Fluorescence Spectra Simulation UI (FluoSimUI)</h3> <p align="center"> A MATLAB-based UI for visualizing fluorescence spectra and evaluating the impact of different optical elements <br /> <a href="https://github.com/your_username/FluoSimUI"><strong>Explore the docs »</strong></a> <br /> <br /> <a href="https://github.com/kscrudders/FluoSimUI/issues">Report Bug</a> · <a href="https://github.com/kscrudders/FluoSimUI/issues">Request Feature</a> </p> </div> <!-- TABLE OF CONTENTS --> <details> <summary>Table of Contents</summary> <ol> <li><a href="#about-the-project">About The Project</a></li> <li><a href="#built-with">Built With</a></li> <li><a href="#getting-started">Getting Started</a> <ul> <li><a href="#prerequisites">Prerequisites</a></li> <li><a href="#installation">Installation</a></li> </ul> </li> <li><a href="#usage">Usage</a></li> <li><a href="#roadmap">Roadmap</a></li> <li><a href="#contributing">Contributing</a></li> <li><a href="#license">License</a></li> <li><a href="#contact">Contact</a></li> <li><a href="#acknowledgments">Acknowledgments</a></li> </ol> </details> <!-- ABOUT THE PROJECT -->
About The Project
FluoSimUI is a MATLAB-based graphical user interface (GUI) designed to streamline the selection and visualization of fluorophore excitation and emission spectra. The tool allows users to:

- Search and select fluorophores from a database pulled from the public repository FPbase.
- Apply excitation and emission filters to visualize spectral data. Example theoritical filters from Semrock.
- Integrate laser excitation lines.
- Adjust for camera quantum yield. Example theoritical quantum yeild for an EMCCD from Andor.
- Generate customizable plots for fluorescence imaging setup optimization.

This tool is useful for researchers and microscopists working with fluorescence-based imaging and spectroscopy.

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- BUILT WITH -->

Built With Matlab and Matlab Toolboxs:
- MATLAB (test on R2024b, should work on much older versions of Matlab)
	
Publically available and Free to use data (both curated and theoritical data)
* Fluorophore Ex/Em spectra from https://www.fpbase.org/ (curated actual data)
* Filter information from https://www.idex-hs.com/ (theoritical filter transmission data, unless you request your specific lot information)
* EMCCD camera quantum yeild information from https://andor.oxinst.com/assets/uploads/products/andor/documents/andor-ixon-life-emccd-specifications.pdf (theoritical quantum yield, unless you request your specific lot information)


<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- GETTING STARTED -->

Getting Started </p>
These instructions will help you set up and run the FluoSimUI on your local machine.

Prerequisites:
Ensure you have the following installed:
- MATLAB
- Fluorophore spectral data files (CSV format, see examples for formating)
- Filter and camera quantum yield data files (CSV format, see examples for formating)

Installation:
* Clone the repository:
* sh
* Copy
* Edit
* git clone https://github.com/kscrudders/FluoSimUI.git

Add to MATLAB path:
* Open MATLAB.
* Go to Home > Set Path > Add Folder and select the cloned folder.

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- USAGE EXAMPLES -->

Usage:
* Open MATLAB and run:
   ```matlab
   fluorophore_plot_UI
   ```
* Use the search bar to find fluorophores by name.
* Select fluorophores and add them to the list.
* Choose optional filters, laser excitation lines, and camera settings.
* Click **Plot Spectra** to visualize the excitation and emission spectra.
* Adjust settings as needed and re-plot.

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- ROADMAP -->

<br /> <div align="center">   <a href="https://github.com/kscrudders/FluoSimUI"> <img src="/FluoSimUI_screenshot.png" alt="GUI Screenshot" width="775" height="600"> </a> 
<div align="left">

## Roadmap

- [ ] Support for additional file formats
- [ ] Integration with online fluorophore databases


See the [open issues](https://github.com/kscrudders/FluoSimUI/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- CONTRIBUTING -->

Contributing: </p>
Contributions make this script more robust and easier to use. If you have suggestions:
* Fork the Project
* Create your Feature Branch (git checkout -b feature/YourFeature)
* Commit your Changes (git commit -m 'Added an awesome feature')
* Push to the Branch (git push origin feature/YourFeature)
* Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- LICENSE -->

License: </p>
This project is distributed under GNU Genereal Public License. </p>
See LICENSE.txt for details.

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- CONTACT -->
Contact </p>
Kevin Scrudders – kscrudders@gmail.com

Project Link: https://github.com/kscrudders/FluoSimUI

<p align="right">(<a href="#readme-top">back to top</a>)</p> <!-- ACKNOWLEDGMENTS -->

Acknowledgments
* The lab of Dr. Shalini T. Low-Nam
* The ever excellent MathWorks Documentation
* The Purdue fluorescence microscopy research community, I learned a lot through our interactions.
* The code was developed in March 2025. The base UI code was drafted using ChatGPT. The math and logic lines were draft by Kevin. All code was reviewed, stress tested, and approved by me, Kevin.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
