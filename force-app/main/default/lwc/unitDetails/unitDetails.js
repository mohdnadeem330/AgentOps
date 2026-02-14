import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getProjectDetailsRecords from '@salesforce/apex/ProjectDocumentUtility.getProjectDetailsRecords';
import getProjectOfferDetailsRecords from '@salesforce/apex/DocumentService.getProjectOfferDetailsRecords';
import getProjectPaymentPlanDetailsRecords from '@salesforce/apex/DocumentService.getProjectPaymentPlanDetailsRecords';
import brokerProjectById from '@salesforce/apex/ViewPropertiesController.brokerProjectById';
import getUnitsById from "@salesforce/apex/UnitServiceWithoutSharing.getUnitsById";
const Project_Details_Page_Icons=resourcesPath+"/ALDARResources/svg/project-details-page-icons/";

export default class UnitDetails extends LightningElement {

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
    propertyIcon=  resourcesPath+"/ALDARResources/svg/PropertyIcon.svg";
    bedsIcon=  resourcesPath+"/ALDARResources/svg/BedIcon.svg";
    downloadVideoOrangeIcon=  resourcesPath+"/ALDARResources/svg/DownloadVideoOrangeIcon.svg";
    addLeadIcon = resourcesPath + "/ALDARResources/svg/ListIcon.svg";
    test1=Project_Details_Page_Icons+"TestImages/Capture1.PNG";
    test2=Project_Details_Page_Icons+"TestImages/Test2.PNG";      
    soldOutIcon = resourcesPath + "/ALDARResources/svg/SoldOut.svg";
    GalleryIcon= resourcesPath + "/ALDARResources/svg/GalleryIcon.svg";
    areaIcon= resourcesPath + "/ALDARResources/svg/AreaIcon.svg";
    completedIcon= resourcesPath + "/ALDARResources/svg/Completed.svg";

    @track projectDescription;
    @track projectTitle;
    @track showSpinner = false;
    amenitiesArray = [];
    imagesArray=[];

    @api passedArray;
    @api selectedRow;

    @track projectId;
    @track unitId;
    @track isResaleUnit = false;
    @track isNewLeadModalOpen = false;

    @track resaleUnitId;
    @track resaleUnitSalesOrderId;
    // @track resaleUnitListedCase;

    createNewResaleLead(){
        this.resaleUnitId = this.unitId;
        this.openNewLeadModal();
    }

    openNewLeadModal() {
        // to open modal set isModalOpen tarck value as true
        this.isNewLeadModalOpen = true;
    }
    closeNewLeadModal() {
        // to close modal set isModalOpen tarck value as false
        this.isNewLeadModalOpen = false;
        // this.getData();
    }
    connectedCallback(){
        this.selectedRow.forEach(selectedRecord => {
            if (selectedRecord.hasOwnProperty('Id')) {
                this.unitId = selectedRecord.Id;
            }
            if (selectedRecord.hasOwnProperty('Project__c')) {
                this.projectId = selectedRecord.Project__c;
            }
            if (selectedRecord.hasOwnProperty('isResale')) {
                this.isResaleUnit = selectedRecord.isResale;
            }
        });
        this.resetAll();
    }

    async resetAll(){
        this.showSpinner = true;

        let selectedProject = [this.projectId];
        const projectData = await getProjectDetailsRecords({projectIds :selectedProject, isResale: this.isResaleUnit});
        const offerData = await getProjectOfferDetailsRecords({projectId : this.projectId , brokerPortalFlag: 'True'});
        const paymentPlanData = await getProjectPaymentPlanDetailsRecords({projectId : this.projectId, brokerPortalFlag: 'True'});

        let selectedUnit = [this.unitId];
        const unitData = await getUnitsById({unitIds: selectedUnit, isResale: this.isResaleUnit});
        const unitDetails = unitData.length > 0 ? unitData[0] : {};
        console.log('unitDetails>>>', unitDetails);
        //resale --- get sales order id for unit
        this.resaleUnitSalesOrderId = unitDetails?.ListedCase__r?.SalesOrder__c; // unitDetails.RelatedSalesOrder__c;
        // this.resaleUnitListedCase = unitDetails?.ListedCase__c;
        
        const projectDetails = await brokerProjectById({projectId : this.projectId});
        console.log('projectDetails>>>', projectDetails);
        this.projectTitle = projectDetails.Name;
        this.projectDescription = projectDetails.Description__c;

        let amenitiesFromProject = projectDetails.Amenities__c;
        if(amenitiesFromProject){
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
        }

    //In case of resale, replace unit name with property code
    if(this.isResaleUnit){
        if (unitDetails.PropertyId__c) {
            this.unitDetailsList.push({
                id:1,
                label:"Unit: ",
                value:unitDetails.PropertyId__c,
                icon:this.propertyIcon,
            })
        } else {
            this.unitDetailsList.push({
                id:1,
                label:"Unit: ",
                value:"",
                icon:this.propertyIcon,
            })
        }
    }else{
        if (unitDetails.Name) {
            this.unitDetailsList.push({
                id:1,
                label:"Unit: ",
                value:unitDetails.Name,
                icon:this.propertyIcon,
            })
        } else {
            this.unitDetailsList.push({
                id:1,
                label:"Unit: ",
                value:"",
                icon:this.propertyIcon,
            })
        }
    }

        if (unitDetails.NumberOfBedrooms__c) {
            this.unitDetailsList.push({
                id:2,
                label:"Number of Beds: ",
                value:unitDetails.NumberOfBedrooms__c,
                icon:this.bedsIcon,
            })
        } else {
            this.unitDetailsList.push({
                id:2,
                label:"Number of Beds: ",
                value:"",
                icon:this.bedsIcon,
            })
        }
        
        if (unitDetails.TotalArea__c) {
            this.unitDetailsList.push({
                id:3,
                label:"Area: ",
                value:unitDetails.TotalArea__c + " sq.mt",
                icon:this.areaIcon,
            })
        } else {
            this.unitDetailsList.push({
                id:3,
                label:"Area: ",
                value:"",
                icon:this.areaIcon,
            })
        }
        
        if (unitDetails.NumberOfCarParks__c) {
            this.unitDetailsList.push({
                id:4,
                label:"Car Parking Spaces: ",
                value:unitDetails.NumberOfCarParks__c,
                icon:this.CoveredParkingIcon,
            })
        } else {
            this.unitDetailsList.push({
                id:4,
                label:"Car Parking Spaces: ",
                value:"",
                icon:this.CoveredParkingIcon,
            })
        }

    if(!this.isResaleUnit){
        if(projectDetails.VirtualTour__c){
            this.descriptionCardsList.push({
                id:2,
                icon: this.virtualTourIcon,
                label:"Virtual Tour",
                URL:projectDetails.VirtualTour__c,
                isOpenInNew:true,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:2,
                icon: this.virtualTourIcon,
                label:"Virtual Tour",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

        if(projectDetails.MapView__c){
            this.descriptionCardsList.push({
                id:3,
                icon: this.viewInMapIcon,
                label:"Map View",
                URL:projectDetails.MapView__c,
                isOpenInNew:true,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:3,
                icon: this.viewInMapIcon,
                label:"Map View",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }

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
    }else{
        if(projectDetails.MapView__c){
            this.descriptionCardsList.push({
                id:1,
                icon: this.viewInMapIcon,
                label:"Map View",
                URL:projectDetails.MapView__c,
                isOpenInNew:true,
                cssClass:"description-card-vertical-view"
            })
        }else{
            this.descriptionCardsList.push({
                id:1,
                icon: this.viewInMapIcon,
                label:"Map View",
                isOpenInNew:false,
                cssClass:"description-card-vertical-view-disabled"
            })
        }
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
        let relatedDocumentTypeWithImages = "Project Gallery";
        // if(this.isResaleUnit){
        //     relatedDocumentTypeWithImages = "Thumbnail";
        // }
        if(projectData[0].relatedDocuments[ relatedDocumentTypeWithImages ]){
            for (let i = 0; i < projectData[0].relatedDocuments[ relatedDocumentTypeWithImages ].length; i++) {
                let currenId = i+1;
                this.imagesArray.push(
                    {
                        id:currenId,
                        index:currenId,
                        poistionId:"slide-"+currenId,
                        poistionId2:"#slide-"+currenId ,
                        src:projectData[0].relatedDocuments[ relatedDocumentTypeWithImages ][i].link
                    }
                )
            }
        }
        this.showSpinner = false;
    }




    descriptionCardsList=[
        // {
        //     id:1,
        //     icon: this.downloadBrochureIcon,
        //     label:"Download Brochure"
        // },
        // {

        //     id:2,
        //     icon: this.virtualTourIcon,
        //     label:"Virtual Tour"
        // },
        // {
        //     id:3,
        //     icon: this.viewInMapIcon,
        //     label:"Map View"
        // },
        // {
        //     id:4,
        //     icon: this.downloadVideoOrangeIcon,
        //     label:"Download Video"
        // }
        
    ];
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
    ];

    unitDetailsList=[

        // {
        //     id:1,
        //     label:"Unit: ",
        //     value:"ALG2-NA1_R1_CON_008-01-01",
        //     icon:this.propertyIcon,
        // },
        // {
        //     id:2,
        //     label:"Number of Beds: ",
        //     value:"3",
        //     icon:this.bedsIcon,
        // },
        // {
        //     id:3,
        //     label:"Area: ",
        //     value:"105.93 sq.mt",
        //     icon:this.areaIcon,
        // },
        // {
        //     id:4,
        //     label:"Car Parking Spaces : ",
        //     value:"2",
        //     icon:this.CoveredParkingIcon,
        // }
    ]

    addtionalDetails=[
        {
            id:1,
            itemName:"Floor Plans",
            icon:this.floorPlans,
            subItems:[]
        },
        {
            id:2,
            itemName:"External Links",
            icon:this.externalLinks,
            subItems:[]
        },
        {
            id:3,
            itemName:"Payment Plans",
            icon:this.paymentPlans,
            subItems:[]
        },
        {
            id:4,
            itemName:"Offers/Promotions",
            icon:this.offersPromotions,
            subItems:[]
        }
    ]

/*
    array=
[
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
*/


generateOffer(){
    const transferDataEvent= new CustomEvent('generateoffer', {
           
        detail: {selected:this.selectedRow}
        // detail: {selectedRow:this.selectedRow}
    });
this.dispatchEvent(transferDataEvent);
}


redirectToManageLead(){

    window.open("../s/manage-leads", "_self");
    
}


handleDownloadImages(){ 
    console.log(this.imagesArray)
    this.downloadImages = this.imagesArray.map(img => img.src);
    console.log(this.downloadImages);

    for(let i = 0; i< this.downloadImages.length; i++){
        window.open(this.downloadImages[i]); 
    }
   
}

closeDetailPage(){
    document.dispatchEvent(new CustomEvent('tabsetdatafromcomponent', {detail : {showNavigationTab:true,currentStep:"view-properties"}}));
   
    this.dispatchEvent(new CustomEvent('closedetailpage', {detail:{isOpen:false}}));
    
}
  }