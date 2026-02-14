import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import uploadFile from '@salesforce/apex/OpportunityUnitSearchController.uploadFile'
import updateMilestoneDetails from '@salesforce/apex/MilestoneConfirmationController.updateMilestoneDetails';
export default class MilestoneConfirmation extends NavigationMixin(LightningElement) {
    @api recordId;
    redirecPageUrl;
    recordLoaded=false;
    isLoading=true;
    proposeNewMilestoneDate=false;
    fileData;
    disableSubmit=true;
    triggerNotification=false;
    finalSubmitDisabled=true;
    get confirmationOptions() {
        return [
            { label: 'Accept', value: 'Accept' },
            { label: 'Propose Extension', value: 'Propose Extension' }
        ];
    }
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
            });
        }
        if(this.recordId && !this.recordLoaded){
           this.recordLoaded=true;
           this.isLoading=false;
           
        }
    }
    checkDisableSubmit(){
        this.disableSubmit = !(this.template.querySelector(".confirmationOptions") && this.template.querySelector(".confirmationOptions").value &&  (  !this.proposeNewMilestoneDate || (this.template.querySelector(".proposedInstallmentDateField") && this.template.querySelector(".proposedInstallmentDateField").value )) );
    }
    handleConfirmationChange(event){
        if(event.target.value == 'Propose Extension' ){
            this.proposeNewMilestoneDate=true;
        }else{
            this.proposeNewMilestoneDate=false;;
        }
        this.checkDisableSubmit();
    }
    handleNotificationTrigger(event){
        this.triggerNotification=event.target.checked;
    }

    handleConfirm(event){
        this.finalSubmitDisabled=!event.target.checked;
    }
    handleSubmit() {
        this.isLoading=true;
        let proposedDate = this.template.querySelector(".proposedInstallmentDateField") && this.template.querySelector(".proposedInstallmentDateField").value ? this.template.querySelector(".proposedInstallmentDateField").value : '';
        let comments = this.template.querySelector(".comments") && this.template.querySelector(".comments").value ? this.template.querySelector(".comments").value : '';
        
        this.triggerNotification = proposedDate==''?false:this.triggerNotification;
        updateMilestoneDetails({recordID : this.recordId  , proposedDate : (proposedDate ==''?undefined:new Date(proposedDate)), triggerNotification : this.triggerNotification , comments : comments })
        .then(data => {
            if(this.fileData){
                this.uploadFileData();
            }
            else{
                setTimeout(() => {
                    window.location.href=this.redirecPageUrl;
                }, 500);    
            }
        }).catch(error => {
            console.log('Unable to save record'+ JSON.stringify(error));
            var errorMsg = error.message;
            if(error.body.pageErrors){
                for(let i = 0 ; i < error.body.pageErrors.length ; i++){
                    errorMsg = error.body.pageErrors[i].message;
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

    uploadFileData(){
        uploadFile({ base64 : this.fileData.base64 , filename : this.fileData.filename, recordId : this.recordId}).then(data=>{
            this.fileData = null;
            setTimeout(() => {
                window.location.href=this.redirecPageUrl;
            }, 500);    
        }).catch(error => {
            this.isLoading=false;
            console.log('Unable to save record'+ JSON.stringify(error));
        });
    }
    
    handleDocumentChange(event){
        if(event.target.files){
            console.log(event.target.files);
            const file = event.target.files[0]
            var reader = new FileReader()
            reader.onload = () => {
                var base64 = reader.result.split(',')[1]
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'recordId': this.recordId
                }
                this.isLoading=true;
            }

            reader.onloadend = () => {
                this.isLoading=false;
            }
            reader.readAsDataURL(file);
        }
    }
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}