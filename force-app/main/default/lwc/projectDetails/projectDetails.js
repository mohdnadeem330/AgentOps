import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getProjectDetailsRecords from '@salesforce/apex/ProjectDocumentUtility.getProjectDetailsRecords';
import getProjectOfferDetailsRecords from '@salesforce/apex/DocumentService.getProjectOfferDetailsRecords';
import getProjectPaymentPlanDetailsRecords from '@salesforce/apex/DocumentService.getProjectPaymentPlanDetailsRecords';
import brokerProjectById from '@salesforce/apex/ViewPropertiesController.brokerProjectById';



const Project_Details_Page_Icons=resourcesPath+"/ALDARResources/svg/project-details-page-icons/";


export default class ProjectDetails extends LightningElement {

    searchUnitsIcons= Project_Details_Page_Icons+"SearchUnitsIcons.svg";
    virtualTourIcon= Project_Details_Page_Icons+"VirtualTourIcon.svg";
    vedioIcon= Project_Details_Page_Icons+"VedioIcon.svg";
    downloadBrochureIcon= Project_Details_Page_Icons+"DownloadBrochureIcon.svg";
    viewInMapIcon=Project_Details_Page_Icons+"ViewInMapIcon.svg";
    floorPlans=Project_Details_Page_Icons+"FloorPlansIcon.svg";
    externalLinks=Project_Details_Page_Icons+"ExternallinksIcon.svg";
    paymentPlans=Project_Details_Page_Icons+"PaymentPlans.svg";
    offersPromotions=Project_Details_Page_Icons+"Offers.svg";
    gymIcon=  resourcesPath+"/ALDARResources/svg/GymIcon.svg";
    swimmingPoolIcon=  resourcesPath+"/ALDARResources/svg/SwimmingPoolIcon.svg";
    BuiltInWardrobesIcon=  resourcesPath+"/ALDARResources/svg/WardrobeIcon.svg";
    CoveredParkingIcon=  resourcesPath+"/ALDARResources/svg/CarIcon.svg";
    BalconyIcon=  resourcesPath+"/ALDARResources/svg/BalconyIcon.svg";
    PetsAllowedIcon=  resourcesPath+"/ALDARResources/svg/PetsIcon.svg";
    downloadIcon=  resourcesPath+"/ALDARResources/svg/Download-Icon-no-bg.svg";
    openLink=  resourcesPath+"/ALDARResources/svg/URLIcon.svg";
    soldOutIcon = resourcesPath + "/ALDARResources/svg/SoldOut.svg";
    GalleryIcon= resourcesPath + "/ALDARResources/svg/GalleryIcon.svg";
    completedIcon= resourcesPath + "/ALDARResources/svg/Completed.svg";
    infoIcon= resourcesPath + "/ALDARResources/svg/InfoIcon.svg";
    projectDescription;
    projectTitle;
    projectTag;
    @track showSpinner = false;

    imagesArray=[];
    amenitiesArray=[];

    @api projectId;
    connectedCallback(){
        this.resetAll();
    }

/* Added By Rishu starts 
  showPreview = false;
    dynamicDocumentURL;
    titleForTheDocument = 'Preview Document';
    handlePreviewDocument(event){
             this.showPreview = true;
        // alert(event.currentTarget.dataset.id);
        //alert(JSON.stringify(this.policyData))
        const object = this.policyData.find(obj => obj.id == event.currentTarget.dataset.id);
        // let dL = this.policyData.filter(x => x.id === event.currentTarget.dataset.id).map(x => x.downloadLink);
        //alert(JSON.stringify(object))
        this.dynamicDocumentURL = object.downloadLink; // set dynamic url based on id
   }
handlePreviewEvent(event){
        // alert(event.detail.isOpen);
        this.showPreview = event.detail.isOpen;
    }
Added By Rishu End 
*/ 


    async resetAll(){
        this.showSpinner = true;
        let selectedProject = [this.projectId];
        const projectData = await getProjectDetailsRecords({projectIds :selectedProject});
        const offerData = await getProjectOfferDetailsRecords({projectId : this.projectId , brokerPortalFlag: 'True'});
        const paymentPlanData = await getProjectPaymentPlanDetailsRecords({projectId : this.projectId, brokerPortalFlag: 'True'});
        
        const projectDetails = await brokerProjectById({projectId : this.projectId});
        console.log('projectDetails>>>', projectDetails);
        this.projectTitle = projectDetails.Name;
        this.projectDescription = projectDetails.Description__c;
        this.projectTag = projectDetails.ProjectTag__c;
        const showTag = this.template.querySelector('.project-tag');
        if(this.projectTag === '' || this.projectTag == null){
            showTag.style.display = "none";
        }

        let amenitiesFromProject = projectDetails.Amenities__c;
        if(amenitiesFromProject != '' && amenitiesFromProject != null){
            let projectAmenities = [];
            projectAmenities = amenitiesFromProject.split(";");
            for (let i = 0; i < projectAmenities.length; i++) {
                console.log(projectAmenities[i]);
                this.amenitiesArray.push({
                    id: i + 1,
                    label: projectAmenities[i],
                    icon: this.completedIcon
                })
            }
        }else{
            const showAmenities = this.template.querySelector('.amenities-title');
            showAmenities.style.display = "none";
        }

        this.descriptionCardsList=[];
        this.descriptionCardsList.push({
            id:1,
            icon:this.searchUnitsIcons,
            label:"Search Units",
            URL:"../s/search-units-page?projectId="+this.projectId,
            isOpenInNew:false,
            cssClass:"description-card-vertical-view"
            
        })
        if(projectDetails.VirtualTour__c){
            this.descriptionCardsList.push({
                id:2,
                icon: this.virtualTourIcon,
                label:"Sales kiosk",
                URL:projectDetails.VirtualTour__c,
                isOpenInNew:true,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:2,
                icon: this.virtualTourIcon,
                label:"Sales kiosk",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

        // if(projectDetails.MapView__c){
        //     this.descriptionCardsList.push({
        //         id:3,
        //         icon: this.viewInMapIcon,
        //         label:"Map View",
        //         URL:projectDetails.MapView__c,
        //         isOpenInNew:true,
        //         cssClass:"description-card-vertical-view"
        //     })
        // }else{
        //     this.descriptionCardsList.push({
        //         id:3,
        //         icon: this.viewInMapIcon,
        //         label:"Map View",
        //         isOpenInNew:false,
        //         cssClass:"description-card-vertical-view-disabled"
        //     })
        // }

        if(projectDetails.VideoLink__c){
            this.descriptionCardsList.push({
                id:4,
                icon: this.vedioIcon,
                label:"Video",
                URL:projectDetails.VideoLink__c,
                isOpenInNew:true,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:4,
                icon: this.vedioIcon,
                label:"Video",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

        if(projectData[0].relatedDocuments.Brochure){
            this.descriptionCardsList.push({
                id:5,
                icon: this.downloadBrochureIcon,
                label:"Download Brochure",
                URL: projectData[0].relatedDocuments.Brochure[0].link,
                isOpenInNew:false,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:5,
                icon: this.downloadBrochureIcon,
                label:"Download Brochure",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

        if(projectData[0].relatedDocuments["Brochure - Arabic"]){
            this.descriptionCardsList.push({
                id:6,
                icon: this.downloadBrochureIcon,
                label:"Download Arabic Brochure",
                URL: projectData[0].relatedDocuments["Brochure - Arabic"][0].link,
                isOpenInNew:false,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:6,
                icon: this.downloadBrochureIcon,
                label:"Download Arabic Brochure",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

        if(projectData[0].relatedDocuments["Master Plan"]){
            projectData[0].relatedDocuments["Master Plan"].forEach(masterPlan => {
                this.addtionalDetails[0].subItems.push(
                    {
                        id:masterPlan.uid,
                        label:masterPlan.name,
                        icon:this.downloadIcon,
                        url: masterPlan.link,
                    }
                )
            });
        }

        if(projectData[0].relatedDocuments["Fact Sheet"]){
            projectData[0].relatedDocuments["Fact Sheet"].forEach(factSheet => {
                this.addtionalDetails[1].subItems.push(
                    {
                        id:factSheet.uid,
                        label:factSheet.name,
                        icon:this.downloadIcon,
                        url: factSheet.link,
                    }
                )
            });
        }
        
        if(projectData[0].relatedDocuments["Brand Style Guide"]){
            projectData[0].relatedDocuments["Brand Style Guide"].forEach(brandStyle => {
                this.addtionalDetails[1].subItems.push(
                    {
                        id:brandStyle.uid,
                        label:brandStyle.name,
                        icon:this.downloadIcon,
                        url: brandStyle.link,
                    }
                )
            });
        }

        if(paymentPlanData["Payment Plan"]){
            paymentPlanData["Payment Plan"].forEach(paymentPlan => {
                this.addtionalDetails[2].subItems.push(
                    {
                        id:paymentPlan.uid,
                        label:paymentPlan.name,
                        icon:this.downloadIcon,
                        url: paymentPlan.link,
                    }
                )
            });
        }

        if(offerData["Offers & Promotions"]){
            offerData["Offers & Promotions"].forEach(offersPromotions => {
                this.addtionalDetails[3].subItems.push(
                    {
                        id:offersPromotions.uid,
                        label:offersPromotions.name,
                        icon:this.downloadIcon,
                        url: offersPromotions.link,
                    }
                )
            });
        }

        if(projectData[0].relatedDocuments["Project Gallery"]){
            for (let i = 0; i < projectData[0].relatedDocuments["Project Gallery"].length; i++) {
                let currenId = i+1;
                this.imagesArray.push(
                    {
                        id:currenId,
                        index:currenId,
                        poistionId:"slide-"+currenId,
                        poistionId2:"#slide-"+currenId ,
                        src:projectData[0].relatedDocuments["Project Gallery"][i].link
                    }
                )
            }
        }
        this.showSpinner = false;
    }

    renderedCallback() {
        this.setBackgroundImage();        
        // Promise.all([
        //     loadStyle(this, resourcesPath+"/ALDARResources/external-libraries/flickity.css" ),
        //     loadScript(this,resourcesPath+"/ALDARResources/external-libraries/flickity.pkgd.min.js")
        

        // ]).then(() => {
        //         console.log('Files loaded.');
        //     })
        //     .catch(error => {
        //         console.log(error.body.message);
        //     });
        
    }

    setBackgroundImage() {
        //console.clear();
        const divs = this.template.querySelectorAll('.image-side');
        if (divs) {
            for (let index = 0; index < divs.length; index++) {
                divs[index].style.backgroundImage=divs[index].getAttribute("data-bgimg");
                if(this.array[index].soldOut){
                    divs[index].style.filter="brightness(50%)";
                }
            }
        }
    }


    descriptionCardsList=[
        
    ]

    amenitiesList=[

        {
            id:1,
            label:"Gym",
            icon:this.gymIcon,
        },
        {
            id:2,
            label:"Swimming Pool",
            icon:this.swimmingPoolIcon,
        },
        {
            id:3,
            label:"Built-in Wardrobes",
            icon:this.BuiltInWardrobesIcon,
        },
        {
            id:4,
            label:"Covered Parking",
            icon:this.CoveredParkingIcon,
        },
        {
            id:5,
            label:"Balcony",
            icon:this.BalconyIcon,
        },
        {
            id:6,
            label:"Pets Allowed",
            icon:this.PetsAllowedIcon,
        }
    ]

    addtionalDetails=[
        {
            id:1,
            itemName:"Floor Plans",
            icon:this.floorPlans,
            subItems:
            [
               
            ]
        },
        {
            id:2,
            itemName:"External Links",
            icon:this.externalLinks,
            subItems:
            [
                
            ]
        },
        {
            id:3,
            itemName:"Payment Plans",
            icon:this.paymentPlans,
            subItems:
            [
                
            ]
        },
        {
            id:4,
            itemName:"Offers/Promotions",
            icon:this.offersPromotions,
            subItems:
            [
                
            ]
        }
    ]

    array=[
        {
            id:1,
            newlyLaunched:true,
            hotProperty:false,
            soldOut:false,
            photosCount:8,
            title:"Mamsha",
            subTitle:"APARTMENTS",
            body:"Mamsha Al Saadiyat offers a range of 1-bedroom to 4-bedroom apartments, as well as limited lofts and townhouses. Set on a prime beachfront property on Saadiyat Cultural District, the residences...",
            startingFromValue:"AED 750,999.00",
            unitsAvailableValue:"24",
            bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
        },
        {
            id:2,
            newlyLaunched:false,
            hotProperty:false,
            soldOut:true,
            photosCount:6,
            title:"Mayan Project",
            subTitle:"TOWNHOUSE",
            body:"MAYAN comprises of seven contemporary buildings overlooking clear blue waters, stunning natural mangroves and lush green fairways of the Yas Links golf course.",
            startingFromValue:"AED 799,999.00",
            unitsAvailableValue:"AED 799,999.00",
            bgImage:"url(../resource/ALDARResources/ALDARResources/png/Image1.png)"
        }
    ]

    closeDetailPage(){
        document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"view-properties"}}));
       
        this.dispatchEvent(new CustomEvent('closedetailpage', {detail:{isOpen:false}}));
        
    }

}