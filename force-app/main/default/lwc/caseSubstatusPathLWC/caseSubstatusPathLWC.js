import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SUB_STATUS_FIELD from '@salesforce/schema/Case.Sub_Status__c';
import updateCaseRecord from '@salesforce/apex/CaseService.updateCaseRecord';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    refreshTab
} from 'lightning/platformWorkspaceApi';


export default class CaseSubstatusPathLWC extends LightningElement {

    //@track selectedValue; //used
    @api recordTypeName;
    @track isModalOpen = false;
    @api recordId;
    @track isLoading = false;
    @api selectedValue; //used
    @track prevstatusVal //used
    @api prevSubstatusVal //used
    //@track RecordTypeIdval
    @api RecordTypeIdval
    @track tempVariable
    ResolvedValue
    @api record // pass Record from parent
    @api picklistSubstatusValues
    @track recordadata
    // @track picklistValues;
        
    connectedCallback(){
        console.log('***SubComponent***' +JSON.stringify(this.record) + JSON.stringify(this.picklistSubstatusValues));
        // this.picklistSubstatusValues = Object.assign({},this.picklistSubstatusValues);
    
    }

      get picklistsubstatValues() {
        let itemsList = [];
         console.log('***SubComponent--picklistsubstatValues-Function***' + JSON.stringify(this.record.data));
                
         if (this.record.data) {            
         
            if(this.record.data.fields.RecordTypeId.value)
                {
                    this.RecordTypeIdval = this.record.data.fields.RecordTypeId.value;
                    console.log('RecordTypeIdval' + this.RecordTypeIdval)
                }
            if(this.record.data.fields.Previous_Status__c.value)
                {
                    this.prevstatusVal = this.record.data.fields.Previous_Status__c.value;
                    console.log('Previous_Status__c' + this.prevstatusVal)
                }
            if(this.record.data.fields.Previous_SubStatus__c.value)
                {
                    this.prevSubstatusVal = this.record.data.fields.Previous_SubStatus__c.value;
                    console.log('prevSubstatusVal' + this.prevSubstatusVal)
                }
               
            if (!this.selectedValue && this.record.data.fields.Sub_Status__c.value) {
                this.selectedValue = this.record.data.fields.Sub_Status__c.value + '';
                console.log('entered here this.selectedValue' + this.selectedValue)
            }        
            if (this.picklistSubstatusValues) {
               console.log('***SubComponent***-this.picklistSubstatusValues'+JSON.stringify(this.picklistSubstatusValues));
                let selectedUpTo = 0;
                // this.handlepicklistdata(this.picklistSubstatusValues);
                for (let item in this.picklistSubstatusValues) {                  
    
                    if (Object.prototype.hasOwnProperty.call(this.picklistSubstatusValues, item)) {
                        console.log('Object.prototype.hasOwnProperty.call');
                        let classList;
                        if (this.picklistSubstatusValues[item].value === this.selectedValue) {
                            classList = 'slds-path__item slds-is-active';
                            selectedUpTo++;
                        }
                        else if (this.picklistSubstatusValues[item].value === this.prevSubstatusVal) {
                            classList = 'slds-path__item slds-is-current';                            
                        }
                         else {
                            classList = 'slds-path__item slds-is-incomplete';
                        }

                        itemsList.push({
                            pItem: this.picklistSubstatusValues[item],
                            classList: classList
                        })                        
                    }
                }
                console.log('itemsList2 = ' + JSON.stringify(itemsList));
                return itemsList;
            }
            }
        
        return null;
    }


    handleSelect(event) {
        console.log('Value', event.currentTarget.dataset.value);
        console.log('Prev Status', this.selectedValue);
        this.selectedValue = event.currentTarget.dataset.value;
        if (this.recordTypeName === 'Third Party Payment NOC') {
            this.isModalOpen = true;
        }
    }

    handleCommentChange(event) {
        this.commentText = event.target.value;
    }

    closeModal() {
        this.isModalOpen = false;
        this.commentText = ''; 
    }

    openModal() {
        this.isModalOpen = true;
    }

    saveComment() {
        if (!this.commentText || !this.commentText.trim()) {
            this.showToast('Error', 'Please add comments', 'error');
            return;
        }
        this.isLoading = true;
        this.isModalOpen = false;
        updateCaseRecord({ 
            caseId: this.recordId, 
            newSubStatus: this.selectedValue, 
            commentBody: this.commentText 
        })
            .then(() => {
                this.showToast('Success', 'Sub Status updated!', 'success');
                this.closeModal();               
                window.location.reload();
            })
            .catch((error) => {
                let errorMessage = error.body?.message;
                if (errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    errorMessage = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].trim();
                    errorMessage = errorMessage.split(':')[0].trim();
                    errorMessage = "Error updating record: " + errorMessage;
                }
                this.showToast('Error', errorMessage, 'error');
                this.closeModal();
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            })
        );
    }


}