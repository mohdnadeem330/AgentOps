import { LightningElement, wire, track } from "lwc";
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import brokerProjects from '@salesforce/apex/ViewPropertiesController.brokerProjects';
import getUserProfileDetails from '@salesforce/apex/UserProfileController.getUserProfileDetails';
import PageBlockerEnableButton from '@salesforce/label/c.PageBlockerEnableButton';

export default class ViewProperties extends LightningElement {
    
    PageBlockerEnableButton = PageBlockerEnableButton;
    get enablePageBlocker(){
        return this.PageBlockerEnableButton === 'TRUE';
    }

    //Filter js Start Here// 
    fillter = resourcesPath + '/ALDARResources/svg/fillter.svg';
    buttonClicked;
    @track cssClass = 'filters-items';
    @track iconName = '';
    handleToggleClick() {
        this.buttonClicked = !this.buttonClicked;
        this.cssClass = this.buttonClicked ? 'filters-items showfillter' : 'filters-items';
        this.iconName = this.buttonClicked ? 'utility:check' : '';
    }
    //Filter js End Here// 
    filterIcon = resourcesPath + "/ALDARResources/svg/FilterIcon.svg";
    ResetIcon = resourcesPath + "/ALDARResources/svg/ResetIcon.svg";
    whiteListViewIcon = resourcesPath + "/ALDARResources/svg/WhiteListViewIcon.svg";
    soldOutIcon = resourcesPath + "/ALDARResources/svg/SoldOut.svg";
    GalleryIcon = resourcesPath + "/ALDARResources/svg/GalleryIcon.svg";

    mapViewIcon = resourcesPath + "/ALDARResources/svg/MapIcon.svg";
    //test= resourcesPath + "/ALDARResources/png/Image1.png";

    @track projectValuesArray;
    @track showSpinner = false;
    @track propertyNamePickListFilterValues = [];
    @track propertyNameField = '';
    propertyCityPickListFilterValues = [];
    
    propertyCountryPickListFilterValues = [];
    propertyCountryFieldValue = '';
    isNeedToRenderCityPicklist = false;

    showDetailsPage = false;
    showPhotos = false;
    shownodata= false;
    projectId;

    @track pId;
    @track pName;
    /*
        array =
            [
                {
                    id: 1,
                    newlyLaunched: true,
                    hotProperty: false,
                    soldOut: false,
                    photosCount: 8,
                    title: "Mamsha",
                    subTitle: "APARTMENTS",
                    body: "Mamsha Al Saadiyat offers a range of 1-bedroom to 4-bedroom apartments, as well as limited lofts and townhouses. Set on a prime beachfront property on Saadiyat Cultural District, the residences...",
                    startingFromValue: "AED 750,999.00",
                    unitsAvailableValue: "24",
                    bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
    
                },
                {
                    id: 2,
                    newlyLaunched: false,
                    hotProperty: false,
                    soldOut: true,
                    photosCount: 6,
                    title: "Mayan Project",
                    subTitle: "TOWNHOUSE",
                    body: "MAYAN comprises of seven contemporary buildings overlooking clear blue waters, stunning natural mangroves and lush green fairways of the Yas Links golf course.",
                    startingFromValue: "AED 799,999.00",
                    unitsAvailableValue: "AED 799,999.00",
                    bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
    
                },
                {
                    id: 3,
                    newlyLaunched: false,
                    hotProperty: false,
                    soldOut: false,
                    photosCount: 6,
                    title: "Water’s Edge",
                    subTitle: "APARTMENTS",
                    body: "This is your chance to choose from studio to 3 – bedroom apartments at Water’s Edge on Yas Island, with only a 10% down payment.",
                    startingFromValue: "AED 550,999.00",
                    unitsAvailableValue: "131",
                    bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
    
                },
                {
    
    
    
    
                    id: 4,
                    newlyLaunched: false,
                    hotProperty: true,
                    soldOut: false,
                    photosCount: 7,
                    title: "Yes Acres, The Mongolias",
                    subTitle: "VILLAS",
                    body: "​Yas Acres is one of the most significant new residential developments to be launched in Abu Dhabi by Aldar with a development value of over AED6 billion. Inspired by the concept of Yas Island Living, Yas Acres is located on the northern ...",
                    startingFromValue: "AED 1,019,999.00",
                    unitsAvailableValue: "13",
                    bgImage: "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
                }
            ]
    */


    //background-image: url("../resource/ALDARResources/ALDARResources/png/Image1.png");

    // get disableCitySelection() {
    //     return (!this.propertyCountryField);
    // }

    renderedCallback() {
        this.setBackgroundImage();

    }

    connectedCallback() {
        this.currentLoggedInUserInfo();
        this.getProjectValues();
    }

    handleChange(event) {
        // Added by Moh Sarfaraj for BPE-243 starts 
        if(event.target.name == 'propertyNameField'){ 
            this.propertyCityField = '';
            this.propertyCountryFieldValue = '';
        }

        if(event.target.name == 'propertyCountyField' && this.propertyCountryFieldValue != event.target.value){
            this.isNeedToRenderCityPicklist = true;
            this.propertyCountryFieldValue = event.target.value;
            this.propertyCityField = '';
        }else{
            this.isNeedToRenderCityPicklist = false;
        }
        // Added by Moh Sarfaraj for BPE-243 end
      
        this[event.target.name] = event.target.value;
        this.getProjectFilteredValues();
    }

    async getProjectFilteredValues() {
        // console.log('this.propertyNameField ' + this.propertyNameField);
        // console.log('this.propertyCityField ' + this.propertyCityField);
         // Added by Moh Sarfaraj for BPE-243 
        let renderedCity = [{ label: " All Cities", value: '' }];
        let renderedCountry = [{ label: " All Countries", value: '' }];

        this.showSpinner = true;
        let projectValues = await brokerProjects({ projectName: this.propertyNameField, projectCity: this.propertyCityField, projectCountry : this.propertyCountryFieldValue });
        // console.log(projectValues);
        this.projectValuesArray = [];

        for (let i = 0; i < projectValues.length; i++) {
            this.projectValuesArray.push({
                id: projectValues[i].projectId,
                newlyLaunched: false,
                hotProperty: false,
                soldOut: false, //projectValues[i].numberOfUnits && projectValues[i].numberOfUnits > 0 ? false: true,
                photosCount: projectValues[i].imageCount && projectValues[i].imageCount != null ? projectValues[i].imageCount : 0,
                showPhotosCount: projectValues[i].imageCount && projectValues[i].imageCount != null && projectValues[i].imageCount > 0 ? true : false,
                title: projectValues[i].projectName,
                subTitle: projectValues[i].unitTypes,
                body: projectValues[i].projectDescription,
                //startingFromValue: projectValues[i].minPrice,
                currencyIsoCode: projectValues[i].currencyIsoCode,
                projCountry: projectValues[i].projectCountry,
                isUKProject: projectValues[i].projectCountry === 'United Kingdom' ? true :false,
                startingFromValue: projectValues[i].minPrice.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","),
                unitsAvailableValue: projectValues[i].numberOfUnits ? projectValues[i].numberOfUnits : "No Units Available",
                bgImage: projectValues[i].thumbnailURL && projectValues[i].thumbnailURL != '' ? "url(" + projectValues[i].thumbnailURL + ")" : "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
            });
            // if(projectValues[i].photosCount == 0){
            //     document.querySelector(`data-projectid=[${id}]`).classList.add("zero-photos");
            // }
             // Added by Moh Sarfaraj for BPE-243 
            if (projectValues[i].projectCity != null) {
                renderedCity.push({ label: projectValues[i].projectCity, value: projectValues[i].projectCity });
            }
            if (projectValues[i].projectCountry != null) {
                renderedCountry.push({ label: projectValues[i].projectCountry, value: projectValues[i].projectCountry });
            }

        }
        // Added by Moh Sarfaraj for BPE-243 starts 
        if(this.isNeedToRenderCityPicklist){
            const renderedCityData = renderedCity.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                    return acc.concat([current]);
                } else {
                    return acc;
                }
            }, []);
            this.propertyCityPickListFilterValues = renderedCityData;
        }

        // const renderedCountryData = renderedCountry.reduce((acc, current) => {
        //     const x = acc.find(item => item.label === current.label);
        //     if (!x) {
        //         return acc.concat([current]);
        //     } else {
        //         return acc;
        //     }
        // }, []);
        // this.propertyCountryPickListFilterValues = renderedCountryData;
        // Added by Moh Sarfaraj for BPE-243 end 
        if(this.projectValuesArray.length ==0){
            this.shownodata = true;
        }else{
            this.shownodata = false; 
        }
        this.showSpinner = false;
    }

    async getProjectValues() {
        this.showSpinner = true;
        let projectValues = await brokerProjects();
        // console.log(projectValues);
        this.projectValuesArray = [];

        let propertyNameFilterDataSet = [{ label: " All Properties", value: '' }];
        let propertyCityFilterDataSet = [{ label: " All Cities", value: '' }];
        // Added by Moh Sarfaraj for BPE-243
        let propertyCountryFilterDataSet = [{ label: " All Countries", value: '' }];


        for (let i = 0; i < projectValues.length; i++) {

            this.projectValuesArray.push({
                id: projectValues[i].projectId,
                newlyLaunched: false,
                hotProperty: false,
                soldOut: false, //projectValues[i].numberOfUnits && projectValues[i].numberOfUnits > 0 ? false: true,
                photosCount: projectValues[i].imageCount && projectValues[i].imageCount != null ? projectValues[i].imageCount : 0,
                showPhotosCount: projectValues[i].imageCount && projectValues[i].imageCount != null && projectValues[i].imageCount > 0 ? true : false,
                title: projectValues[i].projectName,
                subTitle: projectValues[i].unitTypes,
                body: projectValues[i].projectDescription,
                currencyIsoCode: projectValues[i].currencyIsoCode,
                projCountry: projectValues[i].projectCountry,
                isUKProject: projectValues[i].projectCountry === 'United Kingdom' ? true :false,
                startingFromValue: projectValues[i].minPrice.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","),
                unitsAvailableValue: projectValues[i].numberOfUnits ? projectValues[i].numberOfUnits : "No Units Available",
                bgImage: projectValues[i].thumbnailURL && projectValues[i].thumbnailURL != '' ? "url(" + projectValues[i].thumbnailURL + ")" : "url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
            });

            propertyNameFilterDataSet.push({ label: projectValues[i].projectName, value: projectValues[i].projectName });
            if (projectValues[i].projectCity != null) {
                propertyCityFilterDataSet.push({ label: projectValues[i].projectCity, value: projectValues[i].projectCity });
            }

            // Added by Moh Sarfaraj for BPE-243
            if(projectValues[i].projectCountry != null ){
                propertyCountryFilterDataSet.push({ label: projectValues[i].projectCountry, value: projectValues[i].projectCountry })
            }
        }
    
        if(this.projectValuesArray.length ==0){
            this.shownodata = true; 
        }else{
            this.shownodata = false; 
        }
        this.showSpinner = false;
        // console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        // console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        // console.log(projectValues);
        // console.log(JSON.stringify(projectValues));
        // console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        // console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");

        const propertyCityFilterData = propertyCityFilterDataSet.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
                return acc.concat([current]);
            } else {
                return acc;
            }
        }, []);

        // Added by Moh Sarfaraj for BPE-243
        const propertyCountryFilterData = propertyCountryFilterDataSet.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
                return acc.concat([current]);
            } else {
                return acc;
            }
        }, []);

        this.propertyNamePickListFilterValues = propertyNameFilterDataSet.sort((a, b) => a.label.localeCompare(b.label));
        this.propertyCityPickListFilterValues = propertyCityFilterData.sort((a, b) => a.label.localeCompare(b.label));
        // Added by Moh Sarfaraj for BPE-243
        this.propertyCountryPickListFilterValues = propertyCountryFilterData.sort((a, b) => a.label.localeCompare(b.label));

        this.propertyNameField = ''; 
        this.propertyCityField = '';
        // Added by Moh Sarfaraj for BPE-243
        this.propertyCountryFieldValue = '';
    }

    setBackgroundImage() {
        //console.clear();
        const divs = this.template.querySelectorAll('.image-side');
        if (divs) {
            for (let index = 0; index < divs.length; index++) {
                divs[index].style.backgroundImage = divs[index].getAttribute("data-bgimg");

                if (this.projectValuesArray[index]?.soldOut) {
                    divs[index].style.filter = "brightness(50%)";
                }
            }
        }
    }


    openDetailsPage(event) {
        this.projectId = event.target.dataset.id;
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', { detail: { showNavigationTab: false, currentStep: "project-details" } }));
        this.showDetailsPage = true;
    }

    handleCloseDetailPage(event) {
        this.showDetailsPage = event.detail.isOpen;

    }


    openPhotosModal(event) {
        this.pId = event.target.dataset.projectid;
        this.pName = event.target.dataset.projectname;
        this.showPhotos = true;
    }

    handleClosePhotosModal(event) {
        // to close modal set isModalOpen tarck value as false
        //this event has been fired from the modal component it self
        this.showPhotos = event.detail.isOpen;
    }

    // get showMainPage() {
    //     if (!this.showPhotos && !this.showDetailsPage) {
    //         return true
    //     } else {
    //         return false;
    //     }
    // }

    get nUnites() {
        return unitsAvailableValue.length > 0;
    }

    // Added By Moh Sarfaraj for BPM-662 starts
    isLeadButtonVisible = false;
    currentLoggedInUserInfo(){
        getUserProfileDetails()
        .then(results=>{
            if(results?.Profile?.Name != 'Agency Admin' && 
               results?.Profile?.Name != 'Agency Admin Login' && 
               results?.Contact?.BrokerType__c != 'Agency Admin'){

                this.isLeadButtonVisible = true;
            }else{
                this.isLeadButtonVisible = false;
            }
        })
        .catch(error=>{
        })
    }

    handleLeadclick(event){
		sessionStorage.setItem("dashboardAction", "openCreateLead" );
		window.open("../s/manage-leads", "_self");
	}
    // Added By Moh Sarfaraj for BPM-662 end
}