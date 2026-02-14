import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getApplicableSubStatus from '@salesforce/apex/SalesOrderSubStatusController.getApplicableSubStatus';
import saveSubStatus from '@salesforce/apex/SalesOrderSubStatusController.saveSubStatus';
import getSARejectionReason from '@salesforce/apex/SalesOrderSubStatusController.getSARejectionReason';
import getLegalSubmissionReason from '@salesforce/apex/SalesOrderSubStatusController.getLegalSubmissionReason';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
export default class SalesOrderSubStatus extends LightningElement {
    @api recordId;
    recordLoaded =false;;
    profileName;
    allProfileToSubStatusMap;
    isLoading=false;
    subStatusValues;
    selectedSubStatus;
    SARejectionReasonOptions;
    LegalSubmissionReasonOptions;
    isSpinner=false;

    get showLegalVal(){
        return (this.selectedSubStatus == 'Submitted to Legal');
    }

    get showSARejectionVal(){
        return (this.selectedSubStatus == 'Rejected By Sales Admin');
    }
    @wire(getSARejectionReason)
    SARejectionReason({ error, data }) {
        if (data) {
            this.SARejectionReasonOptions = data;
            
        } else if (error) {
            this.SARejectionReasonOptions = undefined;
        }
    }
    @wire(getLegalSubmissionReason)
    LegalSubmissionReason({ error, data }) {
        if (data) {
            this.LegalSubmissionReasonOptions = data;
            
        } else if (error) {
            this.LegalSubmissionReasonOptions = undefined;
        }
    }
    /*
    @wire(getRecord, {recordId: strUserId,fields: [PROFILE_NAME_FIELD]}) 
    wireuser({ error, data}) {
        if (error) {
            this.error = error ; 
        } else if (data) {
            this.profileName =data.fields.Profile.value.fields.Name.value;        
        }
    } */
    connectedCallback(){
        //this.fetchApplicableRecords();
    }
    renderedCallback(){
        if(this.recordId && !this.recordLoaded){
            this.fetchApplicableRecords();
            this.recordLoaded=true;
        }
    }
    fetchApplicableRecords(){
        getApplicableSubStatus({recordId : this.recordId })
        .then(data => {
            this.subStatusValues = data;
        })
        .catch(error => {
            this.subStatusValues = undefined;
        });
    }

    /*@wire(getApplicableSubStatus,{recordId: '$recordId'})
    getApplicableRecords({ error, data }) {
        if (data) {
            this.subStatusValues = data;
            
        } else if (error) {
            this.subStatusValues = undefined;
        }
    }*/

    /*get subStatusValues() {
        var optionsToReturn =[];
        for(var tempProfileName in this.allProfileToSubStatusMap){
            if(tempProfileName === this.profileName){
                for(let i = 0; i < this.allProfileToSubStatusMap[tempProfileName].length; i++) {
                    optionsToReturn.push({'label': this.allProfileToSubStatusMap[tempProfileName][i],'value': this.allProfileToSubStatusMap[tempProfileName][i] });
                }
            }
        }
        return optionsToReturn;
    } */
    handleSubStatusChange(event){
        this.selectedSubStatus = event.detail.value;
    }
    handleSubmit() {
        // Add your updateRecord implementation
       
        this.template.querySelector(".subStatus").reportValidity();
        var selectedSubStatusVal = this.template.querySelector(".subStatus")? this.template.querySelector(".subStatus").value:'';
        var legalReasonVal = this.showLegalVal ? this.template.querySelector(".LegalVal").value : '';
        if(this.showLegalVal){
            this.template.querySelector(".LegalVal").reportValidity();
            if(!legalReasonVal || legalReasonVal==''){
                return;
            }
        }
        var SAReasonVal = this.showSARejectionVal ? this.template.querySelector(".SARejectionVal").value : '';
        if(this.showSARejectionVal){
            this.template.querySelector(".SARejectionVal").reportValidity();
            if(!SAReasonVal || SAReasonVal==''){
                return;
            }
            
        }
        var inputRemarks = this.template.querySelector(".inputRemarks") ? this.template.querySelector(".inputRemarks").value : '';
        if(selectedSubStatusVal!=undefined && selectedSubStatusVal!='' ){
            this.isLoading=true;
            this.isSpinner=true;
            saveSubStatus({recordID : this.recordId  , subStatusVal : selectedSubStatusVal , legalReason : legalReasonVal, SAReason: SAReasonVal, remarks: inputRemarks })
            .then(data => {
                // Close the modal window and display a success toast
                this.isSpinner=false;
                if(data=='Success'){
                    this.dispatchEvent(new CloseActionScreenEvent());
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record updated!',
                            variant: 'success'
                        })
                    );
                }else{
                    this.dispatchEvent(new CloseActionScreenEvent());
                    getRecordNotifyChange([{recordId: this.recordId}]);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: data,
                            variant: 'error'
                        })
                    );
                }
                
                this.isLoading=false;
            })
            .catch(error => {
                this.isSpinner=false;
                console.log('Unable to save record'+ JSON.stringify(error));
                var errorJSON = JSON.stringify(error);
                var errorMsg = error.message;
                if(errorJSON.includes('ENTITY_IS_LOCKED')){
                    errorMsg='Special condition is under approval hence cannot be submitted';
                }else{
                    if(error.body.message != undefined && error.body.message != null){
                        if(error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                          errorMsg = error.body.message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].split(':')[0]
                         }
                         else if(error.body.exceptionType != undefined && error.body.exceptionType == 'System.HandledException' ){
                            errorMsg = error.body.message;
                         }
                      }

                    
                   else if(error.body.pageErrors && error.body.pageErrors.length>0){
                        for(let i = 0 ; i < error.body.pageErrors.length ; i++){
                            errorMsg = error.body.pageErrors[i].message;
                            console.log(error.body.pageErrors[i]);
                        }
                    }else if(error.body.fieldErrors && error.body.fieldErrors.SignatureType__c && error.body.fieldErrors.SignatureType__c.length>0){
                        for(let i=0; i< error.body.fieldErrors.SignatureType__c.length ; i++){
                            errorMsg = error.body.fieldErrors.SignatureType__c[i].message;
                            console.log(error.body.fieldErrors.SignatureType__c[i].message);
                        }
                        
                    }else if(error.body.fieldErrors && error.body.fieldErrors.Account__c && error.body.fieldErrors.Account__c.length>0){
                        error.body.fieldErrors.Account__c.forEach(element => {
                            errorMsg = element.message;
                            console.log(errorMsg); 
                        });
                    }
                }
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMsg,
                        variant: 'error'
                    })
                );
                this.isLoading=false;
            });
        }
    }

    handleCancel() {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
     }

}