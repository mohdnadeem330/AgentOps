import { LightningElement, track, wire } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getBrokerAndSalesTeam from "@salesforce/apex/ContactUsController.getBMandSMTeam";
import getloggedInUserDetails from "@salesforce/apex/ContactUsController.getloggedInUserDetails";
import getRegionPicklist from "@salesforce/apex/ContactUsController.getRegionPicklist";
import getSodicTeamMembers from "@salesforce/apex/ContactUsController.getSodicTeamMembers";

import testResourcesPath from '@salesforce/resourceUrl/testImage1';
import testResourcesPath2 from '@salesforce/resourceUrl/testImage2';
// import { getPicklistValues } from 'lightning/uiObjectInfoApi';
// import userRegion from '@salesforce/schema/User.Region__c';


export default class ContactUs extends LightningElement {
    //@track query = 'SELECT Title, Region__c, FirstName, LastName, RoleName__c, Email, MobilePhone, FullPhotoUrl, ProfileName__c, IsActive, Team__c FROM User WHERE IsActive = True AND (RoleName__c IN ( \'Head of Broker Management\', \'Head of Sales - AUH\', \'Head of Sales - DXB\', \'Associate Director of Sales\') OR ProfileName__c IN ( \'Broker Sales Admin\', \'Sales Manager\', \'Broker Manager\') )';
    @track brokerTeamArray = [];
    @track SalesTeamArray = [];
    @track LSQSalesTeamArray = [];
    @track EgyptSalesTeamArray = [];
    @track ReSalesTeamArray = [];
    profileImage1 = testResourcesPath;
    profileImage2 = testResourcesPath2;
    showEgyptSalesTeam = false;
    salesTeamTitle= 'Sales Team'; 
    @track picklistValues;
    @wire(getRegionPicklist, {}) picklistValues;

    // @wire(getPicklistValues,
    //     {
    //         recordTypeId: '$userMetadata.data.defaultRecordTypeId',
    //         fieldApiName: userRegion
    //     }
    // )
    // regionPickList;

    linkedInLogo = resourcesPath + "/ALDARResources/png/Linkedin.png";
    whatsapp = resourcesPath + "/ALDARResources/png/Whatsapp.png";

    async connectedCallback() {
        
        // alert(JSON.stringify(this.regionPickList));
        let state = '';
        let stateCode = '';
        await getloggedInUserDetails()
            .then(result => {

                /*this.brokerTeamArray.push({
                    id: result[0].Account.OwnerId,
                    profileImage: result[0].Account.Owner.FullPhotoUrl,
                    name: (result[0].Account.Owner.FirstName != null ? (result[0].Account.Owner.FirstName + ' ') : '') + result[0].Account.Owner.LastName,
                    postion: 'Agency Support',
                    email: result[0].Account.Owner.Email,
                    mobilePhoneNumber: result[0].Account.Owner.MobilePhone,
                    hasLinkedIn: false,
                    hasWhatsApp: false,
                });*/

                state = result[0].Account.BillingState;
                
            
                if (state == 'Abu Dhabi') {
                    stateCode = 'AUH';
                    this.salesTeamTitle = 'Abu Dhabi Sales Team';
                } else if (state == 'Dubai') {
                    stateCode = 'DXB';
                    this.salesTeamTitle = 'Dubai Sales Team';
                }
                else{
                    state = result[0].Account.BillingCountry;
                }
                // alert(state)

            })
            .catch(error => {
                //exception handling
                this.error = error;
            })

        await getSodicTeamMembers()
        .then(result => {
            result.forEach(element =>{
                this.EgyptSalesTeamArray.push({
                    id: element.Id,
                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                    profileImage: element.Description,
                    postion: element.Title,
                    email: element.Email,
                    emailLink: `mailto:${element.Email}`,
                    mobilePhoneNumber: element.MobilePhone,
                    hasLinkedIn: false,
                    hasWhatsApp: false,
                })
                if(this.EgyptSalesTeamArray.length>0){
                    this.showEgyptSalesTeam = true;
                }
            })
        })

        await getBrokerAndSalesTeam()
            .then(result => {
                result.forEach(element => {
                    if ('Head of Broker Management' == element.RoleName__c) {
                        this.brokerTeamArray.push({
                            id: element.Id,
                            profileImage: element.FullPhotoUrl,
                            name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                            postion: element.RoleName__c,
                            // Added by Moh Sarfaraj for BPE-191
                            //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                           // email: element.Email,
                           // emailLink: `mailto:${element.Email}`,
                            //mobilePhoneNumber: element.MobilePhone,
                            hasLinkedIn: false,
                            hasWhatsApp: false,
                        });
                    }
                });

                result.forEach(element => {
                    if ('Broker Sales Admin' == element.ProfileName__c && 'Broker Management - Sales Admin' == element.RoleName__c) {
                        this.brokerTeamArray.push({
                            id: element.Id,
                            profileImage: element.FullPhotoUrl,
                            name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                            postion: 'Admin Broker Management',
                            // Added by Moh Sarfaraj for BPE-191
                            //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                            email: element.Email,
                            emailLink: `mailto:${element.Email}`,
                            //mobilePhoneNumber: element.MobilePhone,
                            hasLinkedIn: false,
                            hasWhatsApp: false,
                        });

                    }
                });
                let count = 0; // Added By Moh Sarfaraj
                result.forEach(element => {
                    if ('Broker Manager' == element.ProfileName__c) {
                        if ('AUH' == stateCode && 'Broker Relations Manager - AUH' == element.RoleName__c) {
                            if ('AUH' == element.Team__c) {
                                //alert(element.Id)
                                this.brokerTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: element.BrokerTitle__c,
                                    // Added by Moh Sarfaraj for BPE-191
                                    //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                                ++count; // Added By Moh Sarfaraj
                            }
                        } else if ('DXB' == stateCode && 'Broker Relations Manager - DXB' == element.RoleName__c) {
                            if ('DXB' == element.Team__c) {
                                this.brokerTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: element.BrokerTitle__c,
                                    // Added by Moh Sarfaraj for BPE-191
                                    //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                                ++count; // Added By Moh Sarfaraj
                            }
                        }
                         else if(this.picklistValues.data.includes(state)){  // Added By Moh Sarfaraj for BPE-8 starts
                            if(element.Region__c){
                                // Brokers Except Dubai and Abu Dhabi
                                let regions = element.Region__c.split(';');
                                if(regions.includes(state)){
                                    this.brokerTeamArray.push({
                                        id: element.Id,
                                        profileImage: element.FullPhotoUrl,
                                        name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                        postion: element.BrokerTitle__c,
                                        // Added by Moh Sarfaraj for BPE-191
                                        //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                        email: element.Email,
                                        emailLink: `mailto:${element.Email}`,
                                        mobilePhoneNumber: element.MobilePhone,
                                        hasLinkedIn: false,
                                        hasWhatsApp: false,
                                    });
                                    ++count;
                                }
                            }
                        } 
                    }
                });
                if(count == 0 && !this.picklistValues.data.includes(state)){
                    result.forEach(element => {
                        if ('Broker Manager' == element.ProfileName__c) {
                            this.brokerTeamArray.push({
                                id: element.Id,
                                profileImage: element.FullPhotoUrl,
                                name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                postion: element.BrokerTitle__c,
                                // Added by Moh Sarfaraj for BPE-191
                                //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                email: element.Email,
                                emailLink: `mailto:${element.Email}`,
                                mobilePhoneNumber: element.MobilePhone,
                                hasLinkedIn: false,
                                hasWhatsApp: false,
                            });
                        }
                    });
                } // Added By Moh Sarfaraj for BPE-8 end

                /*result.forEach(element => {
                    if ('Sales Admin' == element.ProfileName__c) {

                        if ('AUH' == stateCode && 'Broker Relations Manager - AUH' == element.RoleName__c) {
                            if ('AUH' == element.Team__c) {
                                this.brokerTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: 'Agency Support',
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                            }
                        } else if ('DXB' == stateCode && 'Broker Relations Manager - DXB' == element.RoleName__c) {
                            if ('DXB' == element.Team__c) {
                                this.brokerTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: 'Agency Support',
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                            }
                        } else if ('Broker Relations Manager - AUH' == element.RoleName__c || 'Broker Relations Manager - DXB' == element.RoleName__c) {
                            this.brokerTeamArray.push({
                                id: element.Id,
                                profileImage: element.FullPhotoUrl,
                                name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                postion: 'Agency Support',
                                email: element.Email,
                                emailLink: `mailto:${element.Email}`,
                                mobilePhoneNumber: element.MobilePhone,
                                hasLinkedIn: false,
                                hasWhatsApp: false,
                            });
                        }
                    }
                });*/
                result.forEach(element => {
                    if ('AUH' == stateCode) {
                        if ('Sales Management' == element.ProfileName__c && ('Head of Sales - AUH' == element.RoleName__c || 'Associate Director of Sales' == element.RoleName__c)) {
                            this.SalesTeamArray.push({
                                id: element.Id,
                                profileImage: element.FullPhotoUrl,
                                name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                postion: element.RoleName__c + ' - ' +stateCode,
                                // Added by Moh Sarfaraj for BPE-191
                                //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                //email: element.Email,
                                //emailLink: `mailto:${element.Email}`,
                                //mobilePhoneNumber: element.MobilePhone,
                                hasLinkedIn: false,
                                hasWhatsApp: false,
                            });
                        }
                    } else if ('DXB' == stateCode) {
                        if ('Sales Manager' == element.ProfileName__c && 'Head of Sales - DXB' == element.RoleName__c) {
                                this.SalesTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: element.RoleName__c + ' - ' +stateCode,
                                    // Added by Moh Sarfaraj for BPE-191
                                    //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                    //email: element.Email,
                                    //emailLink: `mailto:${element.Email}`,
                                    //mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                        }
                    }
                });
                result.forEach(element => {
                     if(element.RoleName__c == 'LSQ - Sales Manager North' || element.RoleName__c == 'LSQ - Sales Manager South'){
                        this.LSQSalesTeamArray.push({
                            id: element.Id,
                            profileImage: element.FullPhotoUrl,
                            name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                            postion: element.RoleName__c,
                            //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                            email: element.Email,
                            emailLink: `mailto:${element.Email}`,
                            mobilePhoneNumber: element.MobilePhone,
                            hasLinkedIn: false,
                            hasWhatsApp: false,
                        });
                    }
                });
                result.forEach(element => {
                    const isFound = this.brokerTeamArray.some(user => {

                        if (user.id == element.Id) {
                            return true;
                        }
                        return false;
                    });

                    if ('AUH' == stateCode) {
                        if ('AUH' == element.Team__c) {
                            if ('Sales Manager' == element.ProfileName__c && !isFound && 'Sales Manager - AUH' == element.RoleName__c) {
                                this.SalesTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: element.RoleName__c,
                                    // Added by Moh Sarfaraj for BPE-191
                                   // languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                            }
                        }
                    } else if ('DXB' == stateCode) {
                        if ('DXB' == element.Team__c) {
                            if ('Sales Manager' == element.ProfileName__c && !isFound && 'Sales Manager - DXB' == element.RoleName__c) {
                                this.SalesTeamArray.push({
                                    id: element.Id,
                                    profileImage: element.FullPhotoUrl,
                                    name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                                    postion: element.RoleName__c,
                                    // Added by Moh Sarfaraj for BPE-191
                                   // languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                                    email: element.Email,
                                    emailLink: `mailto:${element.Email}`,
                                    mobilePhoneNumber: element.MobilePhone,
                                    hasLinkedIn: false,
                                    hasWhatsApp: false,
                                });
                            }
                        }
                    } else if ('Sales Manager - AUH' == element.RoleName__c || 'Sales Manager - DXB' == element.RoleName__c) {
                        this.SalesTeamArray.push({
                            id: element.Id,
                            profileImage: element.FullPhotoUrl,
                            name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                            postion: element.RoleName__c,
                            // Added by Moh Sarfaraj for BPE-191
                            //languages: (element.KnownLanguages__c != null ? element.KnownLanguages__c.replaceAll(';', ', ') : ''),
                            email: element.Email,
                            emailLink: `mailto:${element.Email}`,
                            mobilePhoneNumber: element.MobilePhone,
                            hasLinkedIn: false,
                            hasWhatsApp: false,
                        });
                    }
                });

                result.forEach(element => {
                    if(element.ProfileName__c == 'Resale Relationship Manager'){
                        this.ReSalesTeamArray.push({
                            id: element.Id,
                            profileImage: element.FullPhotoUrl,
                            name: (element.FirstName != null ? (element.FirstName + ' ') : '') + element.LastName,
                            postion: element.RoleName__c,
                            email: element.Email,
                            emailLink: `mailto:${element.Email}`,
                            mobilePhoneNumber: element.MobilePhone,
                            hasLinkedIn: false,
                            hasWhatsApp: false,
                        });
                    }
                })

            })
            .catch(error => {
                //exception handling
                this.error = error;
            })
            
    }

    /*brokerTeamArray = [
        {
            id: 1,
            profileImage: this.profileImage1,
            name: "Sonja Erakovic",
            postion: "Head of Broker Management",
            email: "",
            mobilePhoneNumber: "",
            hasLinkedIn: false,
            hasWhatsApp: false,
        },
        {
            id: 2,
            profileImage: this.profileImage2,
            name: "Irina Mihailov",
            postion: "Agency Support",
            email: "imihailov@aldar.com",
            mobilePhoneNumber: "+971 543682912",
            hasLinkedIn: true,
            hasWhatsApp: true,
        },
        {
            id: 3,
            profileImage: this.profileImage1,
            name: "Abdellah Amin Hasan",
            postion: "Broker Management Team",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 548782711",
            hasLinkedIn: true,
            hasWhatsApp: true,
        }, {
            id: 4,
            profileImage: this.profileImage2,
            name: "Ahmed Hashem",
            postion: "Placeholder Text",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 504941834",
            hasLinkedIn: false,
            hasWhatsApp: true,
        }
    ]
*/

    /*SalesTeamArray = [
        {
            id: 1,
            profileImage: this.profileImage1,
            name: "Sonja Erakovic",
            postion: "Head of Broker Management",
            email: "",
            mobilePhoneNumber: "",
            hasLinkedIn: false,
            hasWhatsApp: false,
        },
        {
            id: 2,
            profileImage: this.profileImage2,
            name: "Irina Mihailov",
            postion: "Agency Support",
            email: "imihailov@aldar.com",
            mobilePhoneNumber: "+971 543682912",
            hasLinkedIn: true,
            hasWhatsApp: true,
        },
        {
            id: 3,
            profileImage: this.profileImage1,
            name: "Abdellah Amin Hasan",
            postion: "Broker Management Team",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 548782711",
            hasLinkedIn: true,
            hasWhatsApp: true,
        }, {
            id: 4,
            profileImage: this.profileImage2,
            name: "Ahmed Hashem",
            postion: "Placeholder Text",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 504941834",
            hasLinkedIn: false,
            hasWhatsApp: true,
        },
        {
            id: 5,
            profileImage: this.profileImage1,
            name: "Abdellah Amin Hasan",
            postion: "Broker Management Team",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 548782711",
            hasLinkedIn: true,
            hasWhatsApp: true,
        }, {
            id: 6,
            profileImage: this.profileImage2,
            name: "Ahmed Hashem",
            postion: "Placeholder Text",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 504941834",
            hasLinkedIn: false,
            hasWhatsApp: true,
        },
        {
            id: 7,
            profileImage: this.profileImage1,
            name: "Sonja Erakovic",
            postion: "Head of Broker Management",
            email: "",
            mobilePhoneNumber: "",
            hasLinkedIn: false,
            hasWhatsApp: false,
        },
        {
            id: 8,
            profileImage: this.profileImage2,
            name: "Irina Mihailov",
            postion: "Agency Support",
            email: "imihailov@aldar.com",
            mobilePhoneNumber: "+971 543682912",
            hasLinkedIn: true,
            hasWhatsApp: true,
        }, {
            id: 9,
            profileImage: this.profileImage1,
            name: "Ahmed Hashem",
            postion: "Placeholder Text",
            email: "aahasan@aldar.com",
            mobilePhoneNumber: "+971 504941834",
            hasLinkedIn: false,
            hasWhatsApp: true,
        }
 
    ]*/


}