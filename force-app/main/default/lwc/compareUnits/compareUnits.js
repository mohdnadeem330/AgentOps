import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getUnitsById from "@salesforce/apex/UnitServiceWithoutSharing.getUnitsById";
import getProjectDetailsRecords from '@salesforce/apex/ProjectDocumentUtility.getProjectDetailsRecords';

// import testImage3 from '@salesforce/resourceUrl/testImage3';
// import testImage4 from '@salesforce/resourceUrl/testImage4';
export default class CompareUnits extends LightningElement {

    @api selectedList;


    areaIcon=resourcesPath+ "/ALDARResources/svg/AreaIcon.svg";
    bedIcon=resourcesPath+ "/ALDARResources/svg/BedIcon.svg";
    propertyIcon=resourcesPath+ "/ALDARResources/svg/PropertyIcon.svg";
    wardrobeIcon=resourcesPath+ "/ALDARResources/svg/WardrobeIcon.svg";
    petsIcon=resourcesPath+ "/ALDARResources/svg/PetsIcon.svg";
    balconyIcon=resourcesPath+ "/ALDARResources/svg/BalconyIcon.svg";
    gymIcon=resourcesPath+ "/ALDARResources/svg/GymIcon.svg";
    carIcon=resourcesPath+ "/ALDARResources/svg/CarIcon.svg";
    swimmingPoolIcon=resourcesPath+ "/ALDARResources/svg/SwimmingPoolIcon.svg";
    completedIcon = resourcesPath + "/ALDARResources/svg/Completed.svg"; // added by Moh Sarfaraj for BPM-326


    @track isResaleUnit = false;
    @track unitList = [];
    @track showSpinner = false;
    // array = [
    //     {
    //         id: 1,
    //         imgSrc: testImage3,
    //         name:"Al Reeman-C1–Q-201-",
    //         price:"AED 900,999",
    //         details:
    //             [
    //                 { id: 1, index: 1, iconSrc: this.propertyIcon, label: "Unit", value:"ALG2-NA1_R1_CON_008-01-01" },
    //                 { id: 2, index: 2, iconSrc: this.areaIcon, label: "Area", value:"105.93 sq.mt" },
    //                 { id: 3, index: 3, iconSrc: this.bedIcon, label: "Number of Beds", value:"3" },
    //                 { id: 4, index: 4, iconSrc: this.carIcon, label: "Car Parking Spaces", value:"2" },

    //             ],
    //         amenities:
    //         [
    //             {id: 1, index: 1, iconSrc:this.gymIcon, label: "Gym"},
    //             {id: 2, index: 2, iconSrc: this.balconyIcon, label: "Balcony"},
    //             {id: 3, index: 3, iconSrc: this.swimmingPoolIcon, label: "Swimming Pool"},
    //             {id: 4, index: 4, iconSrc: this.wardrobeIcon, label: "Built-in Wardrobes"},
    //             {id: 5, index: 5, iconSrc: this.carIcon, label: "Covered Parking"},
    //             {id: 6, index: 6, iconSrc: this.petsIcon, label: "Pets Allowed"}
    //         ]
        
    //     },{
    //         id: 2,
    //         imgSrc: testImage4,
    //         name:"Al Reeman-C1–Q-201-",
    //         price:"AED 900,999",
    //         details:
    //             [
    //                 { id: 1, index: 1, iconSrc: this.propertyIcon, label: "Unit", value:"ALG2-NA1_R1_CON_008-03-03" },
    //                 { id: 2, index: 2, iconSrc: this.areaIcon, label: "Area", value:"125.11 sq.mt" },
    //                 { id: 3, index: 3, iconSrc: this.bedIcon, label: "Number of Beds", value:"3" },
    //                 { id: 4, index: 4, iconSrc: this.carIcon, label: "Car Parking Spaces", value:"2" },

    //             ],
    //         amenities:
    //         [
    //             {id: 1, index: 1, iconSrc:this.gymIcon, label: "Gym"},
    //             {id: 2, index: 2, iconSrc: this.balconyIcon, label: "Balcony"},
    //             {id: 3, index: 3, iconSrc: this.swimmingPoolIcon, label: "Swimming Pool"},
    //             {id: 4, index: 4, iconSrc: this.wardrobeIcon, label: "Built-in Wardrobes"},
    //             {id: 5, index: 5, iconSrc: this.carIcon, label: "Covered Parking"},
    //             {id: 6, index: 6, iconSrc: this.petsIcon, label: "Pets Allowed"}
    //         ]
        
    //     },{
    //         id: 3,
    //         imgSrc: testImage4,
    //         name:"Al Reeman-C1–Q-201-",
    //         price:"AED 900,999",
    //         details:
    //             [
    //                 { id: 1, index: 1, iconSrc: this.propertyIcon, label: "Unit", value:"ALG2-NA1_R1_CON_008-03-03" },
    //                 { id: 2, index: 2, iconSrc: this.areaIcon, label: "Area", value:"125.11 sq.mt" },
    //                 { id: 3, index: 3, iconSrc: this.bedIcon, label: "Number of Beds", value:"3" },
    //                 { id: 4, index: 4, iconSrc: this.carIcon, label: "Car Parking Spaces", value:"2" },

    //             ],
    //         amenities:
    //         [
    //             {id: 1, index: 1, iconSrc:this.gymIcon, label: "Gym"},
    //             {id: 2, index: 2, iconSrc: this.balconyIcon, label: "Balcony"},
    //             {id: 3, index: 3, iconSrc: this.swimmingPoolIcon, label: "Swimming Pool"},
    //             {id: 4, index: 4, iconSrc: this.wardrobeIcon, label: "Built-in Wardrobes"},
    //             {id: 5, index: 5, iconSrc: this.carIcon, label: "Covered Parking"},
    //             {id: 6, index: 6, iconSrc: this.petsIcon, label: "Pets Allowed"}
    //         ]
        
    //     }
        
    // ];
    @track unitIds = [];
    @track projectIds = []; 
    //amenitiesArray = [];
    connectedCallback() {
        this.selectedList.forEach(selectedRecord => {
            if (selectedRecord.hasOwnProperty('Id')) {
                this.unitIds.push(selectedRecord.Id);
            }
            if (selectedRecord.hasOwnProperty('Project__c')) {
                this.projectIds.push(selectedRecord.Project__c);
            }
        });
        this.resetAll();
    }

    async resetAll(){
        this.showSpinner = true;
        const projectData = await getProjectDetailsRecords({projectIds: this.projectIds});
        const unitData = await getUnitsById({unitIds: this.unitIds,isResale: this.isResaleUnit});
       
        let count = 1;
        unitData.forEach(unit => {
            let imageLink = '';
            for (let i = 0; i < projectData.length; i++) {
                if (projectData[i].projectDetail.Id == unit.Project__c) {
                    imageLink = projectData[i].relatedDocuments["Thumbnail"][0].link;
                    break;
                }
            }
            // Added by Moh Sarfaraj for BPM-326
            let amenitiesFromProject = unit.Project__r.Amenities__c;
            let projectAmenities = [];
            let singleAmenitiesArray = [];
            if(amenitiesFromProject){
                projectAmenities = amenitiesFromProject.split(";");
                for (let i = 0; i < projectAmenities.length; i++) {
                        singleAmenitiesArray.push({
                        id: i + 1,
                        label: projectAmenities[i],
                        iconSrc : this.completedIcon
                    })
                }
            }
            // added by Moh Sarfaraj for BPM-326

            let unitDetail = {
                id: count,
                imgSrc: imageLink,
                name: unit.Name,
                price: unit.CurrencyIsoCode + ' ' + unit.SellingPrice__c, // Updated By Moh Sarfaraj for BPE-324
                details: [
                    { id: 1, index: 1, iconSrc: this.propertyIcon, label: "Unit: ", value: unit.Name },
                    { id: 2, index: 2, iconSrc: this.areaIcon, label: "Area: ", value: (unit.TotalArea__c != null ? unit.TotalArea__c + " sq.mt" : "") },
                    { id: 3, index: 3, iconSrc: this.bedIcon, label: "Number of Beds: ", value: (unit.NumberOfBedrooms__c != null ? unit.NumberOfBedrooms__c : "") }
                    // { id: 4, index: 4, iconSrc: this.carIcon, label: "Car Parking Spaces", value: (unit.NumberOfCarParks__c != null ? unit.NumberOfCarParks__c : "") },
                    // Commented by Moh Sarfaraj for BPM-326
                ],
                amenities : singleAmenitiesArray
                // Commented and updated by Moh Sarfaraj for BPM-326
                // amenities: [
                //     { id: 1, index: 1, iconSrc: this.gymIcon, label: "Gym" },
                //     { id: 2, index: 2, iconSrc: this.balconyIcon, label: "Balcony" },
                //     { id: 3, index: 3, iconSrc: this.swimmingPoolIcon, label: "Swimming Pool" },
                //     { id: 4, index: 4, iconSrc: this.wardrobeIcon, label: "Built-in Wardrobes" },
                //     { id: 5, index: 5, iconSrc: this.carIcon, label: "Covered Parking" },
                //     { id: 6, index: 6, iconSrc: this.petsIcon, label: "Pets Allowed" }
                // ]
            }
            this.unitList.push(unitDetail);
            count++;
        });
        this.showSpinner = false;
    }

    goToDashboard() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }

}