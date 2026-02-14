import { LightningElement, api, wire } from 'lwc';
import createVAAccounts from '@salesforce/apex/ALDVA_VirtualAccount.callCreateVA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkTheProgressOfVACreation from '@salesforce/apex/ALDVA_VirtualAccount.checkTheProgressOfVACreation';
import {refreshApex} from '@salesforce/apex';

const PROCEED_TO_CANCEL_OK = 'Yes';
const CLOSE_X = 'No';

export default class AldvaCreateVirtualAccount extends LightningElement {
    @api recordId;
    askConfirmation;
    inputObj = {}; //Generic obj to pass values to confirm modal comp
    xx_modal_class = 'aldar-modal slds-modal slds-fade-in-open xx_confirm_open';//xx_confirm_open;
    showSpinner = false;
    refreshEventTimer;

    showActions = false;
    showProgress = false;
    
    percentageOfCompletion = null;
    progressOfVACreation; //wire attribute

    @wire(checkTheProgressOfVACreation, {recordId:'$recordId'})
    wireCheckTheProgressOfVACreation (value) {
        this.progressOfVACreation = value;
        const { data, error } = value;
        //{error, data}
        if (error) {
            console.log('Error ',error);
        } else if (data) {
            console.log('data ',data);
            let statusList = {};
            for(let i in data) {
                if(i == 'Success') {
                    statusList.Success = data[i];
                }
                if(i == 'TotalCount') {
                    statusList.TotalCount = data[i];
                }
                if(i == 'ProcessedPercentage') {
                    statusList.ProcessedPercentage = data[i];
                    this.percentageOfCompletion = data[i];
                }
            }
            if(statusList.TotalCount > 0) {
                //Below two lines needs to be uncommented and the next 2 lines needs to be removed. Just for testing. Saran S
                this.showProgress = true;
                this.showActions = false;
                //this.showProgress = false;
                //this.showActions = true;
            } else {
                this.showProgress = false;
                this.showActions = true;
            }
            console.log('statusList -> '+statusList);
            console.log('this.percentageOfCompletion -> '+this.percentageOfCompletion);

            if(this.percentageOfCompletion!=null && this.percentageOfCompletion != 100) {
                console.log('Refreshing in 5');
                //alert(5000);
                this.refreshEventTimer = setTimeout(() => {
                    
                    this.refreshPercentage();
                    console.log('Timer');
                }, 2000);
            } 
            if(this.percentageOfCompletion == 100) {
                console.log('ClearTimer');
                clearTimeout(this.refreshEventTimer);
            }
            
        }
    }

    connectedCallback() {
        let inputObj = {};
        inputObj.recordId = this.recordId; //Pass the recordId
        inputObj.modalHeader = 'Do you want to Create Virtual Account for this Project?'; //Pass the header with more information
        inputObj.modalContent = '';
        inputObj.accepted = false;
        inputObj.declined = false;
        inputObj.acceptBtnLabel = PROCEED_TO_CANCEL_OK;
        inputObj.cancelBtnLabel = CLOSE_X;
        inputObj.dynamicClass = this.xx_modal_class;
        this.inputObj = inputObj;
        //
    }
    
    refreshPercentage() {
        console.log('this.percentageOfCompletion -> '+this.percentageOfCompletion);
        this.showSpinner = true;
        refreshApex(this.progressOfVACreation);
        console.log('this.percentageOfCompletion -> '+this.percentageOfCompletion);
        
        
        this.showSpinner = false;
    }

    handleCreateVA() {
        this.askConfirmation = true;
    }

    handleConfirm(event) {
        console.log('Event -> ',event);
        this.showSpinner = true;
        if(event.detail.accepted) {
            createVAAccounts({recordId:this.recordId})
            .then(result => {
                console.log('result -> '+result);
                this.showActions = false;
                this.showProgress = true;
                this.showCustomToast('Success', 'Request Submitted Successfully.', 'success');
                this.refreshPercentage();
            })
            .catch(error => {
                // TODO Error handling
                console.log('Error ',error);
                this.showCustomToast('Error Occured','Error Occured! Please retry '+e, 'error');
            });
        } else {
            this.showSpinner = false;
        }
        this.askConfirmation = false;
    }

    showCustomToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        }));
    }
}