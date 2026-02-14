// lwcInvoiceTable.js
import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCheckList from "@salesforce/apex/ChecklistRecordPageController.getChecklistDetails";
import updateChecklist from "@salesforce/apex/ChecklistRecordPageController.updateChecklist";
import aldarLogo from '@salesforce/resourceUrl/AldarLogo';

const commissionLineItemsColumns = [
    // {label : 'SR', fieldName : 'rowNumber', type : 'number'},

    { label: 'Commission Line Item #', fieldName: 'linkName', type: 'url', 
        typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}
    },
    { label: 'Unit Number',  fieldName: 'Unit_Number__c',  type: 'text' },
    { label: 'Net Amount', fieldName: 'NetAmount__c', type: 'currency', 
        typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: "code" }
    }, 
    { label: 'Total External Commission', fieldName: 'Total_External_Commission__c',  type: 'currency',
        typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }, currencyDisplayAs: "code" }
    }
]



// "cellAttributes: { style: 'vertical-align: top;' }"

export default class ChecklistRecordPage extends LightningElement {
    @api recordId; 
    @track checklistItems = [];
    aldarLogo = aldarLogo;
    listCommissionLineItems = [];
    checklistRecordId = '';
    remarks;
    isLoading = true;
    commissionLineItemsColumns = commissionLineItemsColumns;
    brokerManageName = '';
    submissionDate = '';
    invoiceNumber = ''
    brokerType = '';
    overallStatusText = 'Pending'
    overallApproved = false;
    overallRejected = false;
    isModalOpen = false;
    isOnLoad = false;
    isAlreadyApproved =  false;

    get disbledButton(){
        if(this.isAlreadyApproved == true){
            return true;
        }
        return false;
    }


    connectedCallback(){
        const today = new Date();
        const yyyy = today.getFullYear();
        let mm = today.getMonth() + 1; // Months start at 0!
        let dd = today.getDate();

        if (dd < 10) dd = '0' + dd;
        if (mm < 10) mm = '0' + mm;

        // today's date
        this.submissionDate = dd + '/' + mm + '/' + yyyy;

        getCheckList({
            recordId : this.recordId
        })
        .then(results=>{
            this.checklistRecordId = results.checklistId;
            this.listCommissionLineItems = results.listCommissionLineItems;
            
            this.brokerManageName = results.brokerManagerName;
            this.invoiceNumber = results.invoiceNumber;
            this.brokerType = results.brokerType;

            let countCLI = 1;
            this.listCommissionLineItems.forEach(function(record){
                record.linkName = '/'+record.Id;
                record.rowNumber = countCLI;
                ++countCLI;
            });
            
            let count = 1;
            if(results.listInnerChecklist.length > 0){
                for(let i=0; i<results.listInnerChecklist.length; i++){

                    
                    let checklist = results.listInnerChecklist[i];
                    let fieldName = checklist.fieldName;
                    let description = checklist.description;
                    let fieldValue = (checklist.fieldValue == 'undefined' ||
                                      checklist.fieldValue == undefined || 
                                      checklist.fieldValue == null) ? 
                                      '' : checklist.fieldValue;

                    let fieldNameRejectionReason = checklist.fieldNameRejectionReason;
                    let fieldValueRejectionReason = (checklist.fieldValueRejectionReason == 'undefined' || 
                                                     checklist.fieldValueRejectionReason == undefined || 
                                                     checklist.fieldValueRejectionReason == null) ? 
                                                     '' : checklist.fieldValueRejectionReason;

                    let isRejected = fieldValue == 'Rejected' ? true : false;

                    const objectData = {
                        id : count,
                        detail : description,
                        key : fieldName,
                        value : fieldValue,
                        approved : fieldValue == 'Approved' ? true : false,
                        rejected : fieldValue == 'Rejected' ? true : false,
                        keyRejectionReason : fieldNameRejectionReason,
                        valueRejectionReason : isRejected == true ? fieldValueRejectionReason : ''
                    }   
                    this.checklistItems.push(objectData);
                    ++count;
                }
            }
            this.isLoading = false;

            this.isOnLoad = true;
            this.updateOverStatus();
            
        }).catch(error=>{
            this.isLoading = false;
        })
    }

    handleChange(event){
        this.remarks = event.target.value;
    }

    handleInputChange(event) {
        const { name, value } = event.target;

        this.checklistItems = this.checklistItems.map(item => {
            
            if (item.id === parseInt(name)) {
                item.valueRejectionReason = value;            
            }
            return { ...item};
        })
    }

    handleCheckboxChange(event) {
        const { name, value, checked } = event.target;

        this.checklistItems = this.checklistItems.map(item => {

            if (item.id === parseInt(name)) {
                if(value == 'approved'){
                    if(checked == true){
                        item.rejected = false;
                        item.approved = true;
                        item.value = 'Approved';
                        item.valueRejectionReason = '';
                    }else{
                        item.approved = false;
                        item.value = 'Pending';
                    }
                }else if(value == 'rejected'){
                    
                    if(checked == true){
                        item.rejected = true;
                        item.approved = false;
                        item.value = 'Rejected';
                    }else{
                        item.rejected = false;
                        item.value = 'Pending';
                    }
                }

                return { ...item};
            }
            return item;
        });

        this.isOnLoad = false;
        this.updateOverStatus(); 
    }

    updateOverStatus(){
        this.isAlreadyApproved = false;

        if(this.checklistItems.length > 0 ){
            let totalApprovedCount = 0;
            let totalRejectedCount = 0;
            let totalPendingCount = 0;

            this.checklistItems.forEach(item=>{
                if(item.approved == true){
                    ++totalApprovedCount;
                }
                if(item.rejected == true ){
                    ++totalRejectedCount;
                }
                if(item.approved == false && item.rejected == false){
                    ++totalPendingCount;
                }
            })

            if(totalRejectedCount > 0){
                this.overallStatusText = 'Rejected';
                this.overallApproved = false;
                this.overallRejected = true;
               
            }else if(totalRejectedCount == 0 && 
                     totalPendingCount == 0 && 
                     totalApprovedCount > 0 && 
                     this.checklistItems.length == totalApprovedCount){

                this.overallStatusText = 'Approved';
                this.overallApproved = true;
                this.overallRejected = false;

            }else {
                this.overallStatusText = 'Pending';
                this.overallApproved = false;
                this.overallRejected = false;
            }
        }

        if(this.overallStatusText == 'Approved' && this.isOnLoad == true){
            this.isAlreadyApproved = true;
        }
    }
 
    async handlePartialSubmit(){
        this.isLoading = true;
        const isInputsCorrect = await [...this.template.querySelectorAll('input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity(); 
                return validSoFar && inputField.checkValidity();
            }, true);

        if(!isInputsCorrect) {
            this.isLoading = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Kindly enter the rejection reason.',
                    variant: 'error',
                })
            );
            this.isLoading = false;
        }else{
            this.isLoading = false;
            if(this.recordId == '' ||  this.recordId == null || this.recordId == undefined || this.checklistItems.length == 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'No action can be performed.',
                        variant: 'warning',
                    })
                );
                this.isLoading = false;
                return; 
            }

            this.isModalOpen = true;
        }
    }

    closeModal(event){
        this.isModalOpen = false;
        this.isLoading = false;
    }
    
    async handleFinalSubmit() {
        this.isModalOpen = false;
        this.isLoading = true;
        
        let checklistRecord = { Id : this.checklistRecordId, 
                                Remarks__c : this.remarks, 
                                OverallStatus__c : this.overallStatusText
                            };

        for(let i=0; i<this.checklistItems.length ; i++){
            checklistRecord[this.checklistItems[i].key] = this.checklistItems[i].value;
            checklistRecord[this.checklistItems[i].keyRejectionReason] = this.checklistItems[i].valueRejectionReason;
        }

        await updateChecklist({
            jsonString : JSON.stringify(checklistRecord)
        })
        .then(results=>{
            if(results == 'success'){
                const evt = new ShowToastEvent({
                    title: 'Sucess',
                    message: 'Checklists are updated successfully!' ,
                    variant: 'success',
                });
                this.dispatchEvent(evt);

                let _baseUrl = window.location.origin + '/lightning/r/Checklist__c/'+this.checklistRecordId +'/view';
                window.open(_baseUrl, "_self");
            }
            this.isLoading = false;
        })
        .catch(error=>{
            
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error.body.message ,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }
}