import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import {CurrentPageReference} from 'lightning/navigation';
import getConversionDetails from '@salesforce/apex/OpportunityRTOUnitSearchController.getConversionDetails';
import convertRTO from '@salesforce/apex/OpportunityRTOUnitSearchController.convertRTO';

export default class ConvertRTO extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading=true;
    conversionDetails;
    disableSubmit=true;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.getAllDOcumentIds();
        }
    }

    handleConfirmSelect(event){
        this.disableSubmit= !event.target.checked;
    }
    
    getAllDOcumentIds(){
        getConversionDetails({recordId : this.recordId })
            .then(data => {
                this.conversionDetails=data;
                console.log(data);
                this.isLoading=false;
            }).catch(error => {
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
   
   
    handleSubmit() {
        this.isLoading=true;
        
        convertRTO({recordId : this.recordId })
        .then(data => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'success',
                    message: 'RTO Converted Successfully',
                    variant: 'success'
                })
            );
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: data,
                    actionName: 'view',
                },
            }).then(url => {
                setTimeout(() => {
                    window.location.href=url;
                }, 500);   
            });

            
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