import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import fetchAllDocumentIDs from '@salesforce/apex/DownloadSODocsController.sendForESign';
import checkSignatureType from '@salesforce/apex/DownloadSODocsController.checkSignatureType';
import SendforDigitalSignature from '@salesforce/apex/DocusignSPAAPI.SendforDigitalSignature';
import sendFasttrackLink from '@salesforce/apex/DownloadSODocsController.sendFasttrackLink';
import SPADescription from "@salesforce/label/c.SPADescription";
import SPADescriptionResident from "@salesforce/label/c.SPADescriptionResident";
import ParkingSendDocusignDescription from "@salesforce/label/c.ParkingSendDocusignDescription";
import SignzyUsers from "@salesforce/label/c.SignzyUsers";
import USER_ID from '@salesforce/user/Id';
import {getRecord} from 'lightning/uiRecordApi';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

export default class DownloadSODocs extends LightningElement {
    @api recordId;
    isLoading=true;
    recordLoaded=false;
    WarningMessage = '';
    isOpenPopup = false;
    isWarning = false;
    selectedvalue='Signzy';
    signatureType ='';
    userEmail;
    openFastTrackFlow = false;
    showFasttrackMessage = false;
    
    @wire(getRecord,{recordId:USER_ID, fields:[EMAIL_FIELD]})
    wiredEmail({data,error}){
        if(data){
            this.userEmail = data.fields.Email.value;
             
        }else if(error){
            console.log('Error while fetching the User Email', error);
        }
    }

    get options() {
        const emailsInLabel = SignzyUsers.split(',').map(email => email.trim().toLowerCase());

        if(emailsInLabel.includes(this.userEmail.toLowerCase())){
        return [
            { label: 'UAE Pass via Live Aldar (Signzy)', value: 'Signzy' },
            { label: 'UAE Pass via Email', value: 'UAEPass' },
        ];
        }else{
              return [
            { label: 'UAE Pass via Live Aldar (Signzy)', value: 'Signzy' }
        ];
        }
        
    }
    updateselectedValue(event){
        this.selectedvalue = event.detail.value;
    }
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            checkSignatureType({recordId : this.recordId })
            .then(data => {
                if(data && data != undefined && data != null && data != ''){
                    this.digitalSignature(data);
                }else{
                    this.getAllDOcumentIds();
                }
            }).catch(error => {
                console.log('Error1',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message || 'Unable to perform this action.',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
            
        }
    }
    digitalSignature(data){
        this.signatureType = data;
        if(data =='SelectDigitalORUAE'){
            this.isSelection = true;
            this.WarningMessage =SPADescriptionResident;
            this.isOpenPopup = true;
            this.isLoading = false;
            
        }else if(data == 'Digital'){
           this.WarningMessage = SPADescription;
           this.isOpenPopup = true;
           this.isLoading = false;
           
        }else if(data =='Parking'){
            this.WarningMessage = ParkingSendDocusignDescription;
           this.isOpenPopup = true;
           this.isLoading = false;
        } else if(data =='Send Fasttrack Link') {
            this.openFastTrackFlow = true;
            this.isLoading = false;
        }
    }
    hideModalBox(){
        this.isOpenPopup = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    digitalSignatureflow(){
        if(this.selectedvalue =='Signzy'){
        this.isLoading = true;
        SendforDigitalSignature({recordId : this.recordId,signType:this.signatureType })
            .then(data => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Document sent for eSignature',
                        variant: 'success'
                    })
                );
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }).catch(error => {
                console.log('Error2',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to perform this action.',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        }else{
            this.getAllDOcumentIds();
        }
    }

    
    getAllDOcumentIds(){
        
            fetchAllDocumentIDs({recordId : this.recordId })
            .then(data => {
                if(data && data != undefined && data !='' &&  data =='Success'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Document sent for eSignature',
                            variant: 'success'
                        })
                    );
                }// Added by Moh Sarfaraj for ASF-1185 on 24 July 2023
                else if(data && data != undefined && data !='' && data == 'Document Unverified'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Error',
                        message: 'Document Validation is not verified by Sales Admin',
                        variant: 'error'
                        })
                    );
                }
                else if(data && data != undefined && data !='' ){
                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Error',
                        message: data,
                        variant: 'error'
                        })
                    );
                }else{
                    console.log('Error3',error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to perform this action.',
                        variant: 'error'
                        })
                    );
                }
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.log('Error4',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to perform this action.',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        
    }

    sendFasttrackLink() {
        this.isLoading = true;

        sendFasttrackLink({recordId : this.recordId })
            .then(data => {
                this.showFasttrackMessage = true;
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message || 'Unable to perform this action.',
                        variant: 'error'
                    })
                );
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            }).finally(()=>{
                this.isLoading = false;
            });
    }
}