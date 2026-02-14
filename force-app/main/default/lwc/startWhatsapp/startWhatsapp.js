import { api, LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getToken from '@salesforce/apex/OutboundCallUtility.getAccessTokenforWhatsapp';
import Id from '@salesforce/user/Id';
import userEmailFIELD from '@salesforce/schema/User.Email';
import userUsernameFIELD from '@salesforce/schema/User.Username';
import userProfileName from '@salesforce/schema/User.Profile.Name';
import startWhatsapp from '@salesforce/apex/OutboundCallUtility.initiateWhatsapp';
import getMobileSobject from '@salesforce/apex/UtilitiesWithoutSharing.getMobileSobject';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import flowidCC from '@salesforce/label/c.GenesysWhatsappFlowCC';
import flowidSM from '@salesforce/label/c.GenesysWhatsappFlowSM';

export default class StartWhatsapp extends LightningElement {
    
    @api recordId;
    @api objectApiName;
    @track isLoading = true;
    @track tokenstring='';
    @track userId = Id;
    @track suppliedflowid;
    @track currentUserEmail;
    @track currentUserProfileName;
    @track customerMobV;
    @track customerLang;
    @track flowidforCC = flowidCC;
    @track flowidforSM = flowidSM;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId: Id, fields: [userEmailFIELD, userUsernameFIELD, userProfileName]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserEmail = data.fields.Email.value;
            this.currentUserName = data.fields.Username.value;
            this.currentUserProfileName = data.fields.Profile.value.fields.Name.value;
        } else if (error) {
            this.error = error ;
        }
    }


    @wire(getMobileSobject, { recordid: '$recordId', sobjectname: '$objectApiName' })
    wireMobileData({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            //this.customerMobV = data.fields.PersonMobilePhone.value;
            console.log('Data>>>' + data);
            //this.customerMobV = data;
            //console.log('Customer Mobile>>>' + this.customerMobV);
            for(var key in data){
                this.customerMobV = key;
                this.customerLang = data[key];
            }
            if (this.customerMobV != undefined || this.customerMobV != null) {
                this.callAPICallout(this.customerMobV, this.currentUserName, this.customerLang);
            } else {
                const evt = new ShowToastEvent({
                    title: 'Mobile Number not found for this record',
                    variant: 'info',
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }
    }

   /* // Below wire method is to send whatsapp to Mobile Phone from Contact
    @wire(getRecord, { recordId: '$recordId', fields: [Contact_Mobile] })
    wireRecordData({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.customerMobV = data.fields.PersonMobilePhone.value;
            console.log('Customer Mobile>>>' + this.customerMobV);
            
            if (this.customerMobV != undefined || this.customerMobV != null) {
                this.callAPICallout(this.recordId, this.customerMobV, this.currentUserEmail);
            } else {
                const evt = new ShowToastEvent({
                    title: 'Mobile Number not found for this record',
                    variant: 'info',
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }
    }*/

    

    async callAPICallout(mob, cemail, clang) {
        this.isLoading = true;
        if(this.tokenstring == ''){
            await getToken({

            }).then(result => {
                console.log('LWC Genesys Whatsapp Token---'+JSON.stringify(result));
                this.tokenstring = result;
                this.suppliedflowid=this.flowidforSM;
                if(this.currentUserProfileName == 'Contact Centre Agent'){
                    this.suppliedflowid=this.flowidforCC;
                }
                startWhatsapp({
                    token: this.tokenstring,
                    flowid: this.suppliedflowid, 
                    agentEmail: cemail, 
                    customerMob: mob,
                    customerLang: clang

                }).then(result => {
                    console.log('Result>>>'+result);
                    const evt = new ShowToastEvent({
                        title: 'Initiating Whatsapp...',
                        variant: 'info',
                    });
                    this.dispatchEvent(evt);
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.isLoading = false;
                }).catch(error => {
                    console.error('error', error);
                    this.isLoading = false;
                })
            })
        }
    }
}