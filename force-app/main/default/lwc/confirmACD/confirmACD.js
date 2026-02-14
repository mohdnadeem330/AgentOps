import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import updateMilestoneDetails from '@salesforce/apex/ConfirmACDController.updateMilestoneDetails';

export default class ConfirmACD extends  NavigationMixin(LightningElement) {
    @api recordId;
    redirecPageUrl;
    recordLoaded=false;
    isLoading=true;
    proposeNewMilestoneDate=false;
    disableSubmit=true;
    triggerNotification=false;
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
    handleSubmit() {
        this.isLoading=true;
        let proposedDate = this.template.querySelector(".proposedInstallmentDateField") && this.template.querySelector(".proposedInstallmentDateField").value ? this.template.querySelector(".proposedInstallmentDateField").value : '';
        
        this.triggerNotification = proposedDate==''?false:this.triggerNotification;
        updateMilestoneDetails({recordID : this.recordId  , proposedDate : (proposedDate ==''?undefined:new Date(proposedDate)), triggerNotification : this.triggerNotification  })
        .then(data => {
           
            setTimeout(() => {
                window.location.href=this.redirecPageUrl;
            }, 500);    
            
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

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}