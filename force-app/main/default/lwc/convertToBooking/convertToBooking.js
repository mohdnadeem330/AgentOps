import { LightningElement , api , wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertReservation from "@salesforce/apex/OpportunityUnitSearchController.convertReservation";
import getWinReasonPickList from "@salesforce/apex/OpportunityUnitSearchController.getWinReasonPickList";
import getsObjectType from '@salesforce/apex/OpportunityUnitSearchController.getsObjectType';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import uploadFile from '@salesforce/apex/OpportunityUnitSearchController.uploadFile';
//import signatureTypes from "@salesforce/apex/OpportunityUnitSearchController.signatureTypes";
import { NavigationMixin } from 'lightning/navigation';
export default class ConvertToBooking extends NavigationMixin(LightningElement) {
    @api recordId;
    winReasonOptions;
    isLoading;
    recordLoaded=false;
    sObjectRecord;
    hasSignatureTypes = false;
    signatureTypesVals;
    get ICACheckRequired(){
        return (this.sObjectRecord && this.sObjectRecord.Opportunity__c && this.sObjectRecord.Opportunity__r.CustomerResidentStatus__c && this.sObjectRecord.Opportunity__r.CustomerResidentStatus__c==='Non-Resident');
    }

    @wire(getWinReasonPickList)
    getWinReasonValues({ error, data }) {
        if (data) {
            this.winReasonOptions = data;
            
        } else if (error) {
            this.winReasonOptions = undefined;
        }
    }
    
    gesObjectData(){
        getsObjectType({recordID :this.recordId })
        .then(data => {
            console.log(this.recordId);
            console.log('--data---');
            console.log(data);
            for(var key in data){
                this.sObjectRecord = data[key];
                console.log(data);
            }
        })
        .catch(error => {
            console.log('Unable to sObject data ==>'+ JSON.stringify(error));
            this.sObjectRecord = undefined;
        });
    }
    handleSubmit() {
        var winReasonValue = this.template.querySelector(".bookingConfirmationWinReason")? this.template.querySelector(".bookingConfirmationWinReason").value:'';
        //var signatureTypeValue = this.template.querySelector(".signatureType")?this.template.querySelector(".signatureType").value:'';
        this.isLoading=true;
        this.handleBookingButtonDisplayLocal();
        convertReservation({recordID : this.recordId  , winReason : winReasonValue})
        .then(data => {
            if(data['message']=='success'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated!',
                        variant: 'success'
                    })
                );
            this.dispatchEvent(new CloseActionScreenEvent());
            if(this.fileData){
                const {base64, filename, recordId} = this.fileData
                uploadFile({ base64, filename, recordId }).then(result=>{
                    this.fileData = null
                })
            }
            //getRecordNotifyChange([{recordId: this.recordId}]);
            
            setTimeout(() => {
                window.location.href=this.redirecPageUrl;
            }, 500);    
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: data['message'],
                        variant: 'error'
                    })
                );
            }
            
            this.isLoading=false;
            this.handleBookingButtonDisplayLocal();
        })
        .catch(error => {
            console.log('Unable to save record'+ JSON.stringify(error));
            var errorMsg = error.message;
            if(error.body.pageErrors){
                for(let i = 0 ; i < error.body.pageErrors.length ; i++){
                    errorMsg = error.body.pageErrors[i].message;
                    console.log(error.body.pageErrors[i]);
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
            this.handleBookingButtonDisplayLocal();
        });
        
        
    }



    disableSubmit=true;
    handleBookingButtonDisplayLocal(){
        if(!this.isLoading && this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked  && this.template.querySelector(".icaVerificationConfirm") && this.template.querySelector(".icaVerificationConfirm").checked  ){
         this.disableSubmit= false;  
        }else{
            this.disableSubmit= true;
        }
    }
    fileData;
    handleBookingButtonDisplay(event){
        console.log('handleBookingButtonDisplay');
        if(event.target.files){
            const file = event.target.files[0]
            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1]
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'recordId': this.sObjectRecord.Opportunity__c
                }
                this.isLoading=true;
            }

            reader.onloadend = () => {
                this.isLoading=false;
                if(this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData ) ){
                    this.disableSubmit= false;
                    /*  if( this.hasSignatureTypes){
                       if(this.template.querySelector(".signatureType") && this.template.querySelector(".signatureType").value)
                        this.disableSubmit= false;
                       }else if(!this.hasSignatureTypes){
                        if(!this.template.querySelector(".signatureType")){
                        this.disableSubmit= false;
                       }
                    } */
                       
                    
                }else{
                    this.disableSubmit= true;
                }
            }

            reader.readAsDataURL(file);
        }
        // console.log('this.fileData');
        // console.log(this.fileData);
        if(this.template.querySelector(".bookingConfirmationWinReason") && this.template.querySelector(".bookingConfirmationWinReason").value && this.template.querySelector(".bookingConfirmationConfirm") && this.template.querySelector(".bookingConfirmationConfirm").checked && (!this.ICACheckRequired || this.fileData ) ){
            this.disableSubmit= false;
          /*  if( this.hasSignatureTypes){
               if(this.template.querySelector(".signatureType") && this.template.querySelector(".signatureType").value)
                this.disableSubmit= false;
               }else if(!this.hasSignatureTypes){
                if(!this.template.querySelector(".signatureType")){
                this.disableSubmit= false;
               }
            } */
               
            
        }else{
            this.disableSubmit= true;
        }
    }
   /* @wire(signatureTypes, {recordId: '$recordId'})
        getsignatureTypes({ error, data }){
         console.log('data:::'+data);
         console.log('error:::'+error);
        if (data) {
            if(data.length>0){
                this.signatureTypesVals = data;
                this.hasSignatureTypes = true;
            }
            
            
        } else if (error) {
            this.signatureTypesVals = undefined;
        }
        
    } */
    handleCancel() {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
     }
    redirecPageUrl;
    renderedCallback(){
        if(!this.redirecPageUrl && this.recordId ){
           
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view',
                },
            }).then(url => {
                this.redirecPageUrl = url;
                console.log('-----'+url);
            });
        }
        if(this.recordId && !this.recordLoaded){
           
            this.gesObjectData();
            console.log('-----');
            this.recordLoaded=true;
        }
    }
}