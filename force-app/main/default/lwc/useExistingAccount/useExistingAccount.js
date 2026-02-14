import { LightningElement,track,api,wire } from 'lwc';
import searchRecords from '@salesforce/apex/UseExistingAccount.getAccount';
import updateOpportunity from '@salesforce/apex/UseExistingAccount.updateOpportunity';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NATIONALITY from '@salesforce/schema/Account.BankCountry__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DuplicationEnabled from '@salesforce/label/c.AccountDuplicationEnabled';
const FIELDS = ['Account.ResidentStatus__pc'];

export default class UseExistingAccount extends LightningElement {
    @track searchKey = '';
    @track records = [];
    @track selectedRecord;
    @api recordId;
    @track selectedRecId;
    @track picklistOptions = [];
    emiratesId;
    passportNumber;
    nationality;
    dateOfBirth;
    resident = false;
    disabled = true;
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NATIONALITY })
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('Picklist options:'+JSON.stringify(data.values));
            this.picklistOptions = data.values;
        } else if (error) {
            console.log('error:'+JSON.stringify(error));
            console.error(error);
        }
    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('AccDate:'+JSON.stringify(data.fields.ResidentStatus__pc.value));
            if(data.fields.ResidentStatus__pc.value==='Resident'){
                this.resident = true;
            }else{
                this.resident = false;
            }
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }
    selectedRow = [];
    columns = [
        
        { label: 'Name', fieldName: 'Name' },
        { label: 'Resident Status', fieldName: 'ResidentStatus__pc' },
        { label: 'National Id Number', fieldName: 'NationalIdNumber__pc' },
        { label: 'Passport Number', fieldName: 'PassportNumber__pc' },
        { label: 'Nationality', fieldName: 'Nationality__pc' },
        { label: 'Date Of Birth', fieldName: 'PersonBirthdate', type: 'date'},
        
    ];

    handleEmiratesIdChange(event) {
        this.emiratesId = event.target.value;
    }

    handlePassportChange(event) {
        this.passportNumber = event.target.value;
    }

    handleNationalityChange(event) {
        this.nationality = event.target.value;
    }

    handleDateOfBirthChange(event) {
        this.dateOfBirth = event.target.value;
    }

    handleSearch() {
        const inputCmp = this.template.querySelector("[data-id='passportnumber']");
        if(DuplicationEnabled == 'false'){
            const evt = new ShowToastEvent({
                title: '',
                message: 'Account search disabled',
                variant: 'error',
            });
            this.dispatchEvent(evt);
            return;
        }
        if(this.resident ===false && (this.passportNumber=== undefined || this.passportNumber === '' || this.passportNumber===null)){
            inputCmp.setCustomValidity("Passport Number is required!");
        }else{
            console.log('test = '+this.emiratesId);
        searchRecords({ recId: this.recordId,nationalId: this.emiratesId,passPortNumber: this.passportNumber,nationality: this.nationality,dateofBirth: this.dateOfBirth })
            .then((result) => {
                this.records = result;
            })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: JSON.stringify(error),
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
        }
        inputCmp.reportValidity();
    }

    
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedRow = [selectedRows[0].Id]; 
            this.disabled = false;
        }
    }
    handleSubmit(event){
        updateOpportunity({ newId: this.selectedRow[0],existingId: this.recordId})
            .then((result) => {
                this.dispatchEvent(new CloseActionScreenEvent());
                window.open('/'+this.selectedRow[0] ,'_self');

            })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: JSON.stringify(error),
                    variant: 'error',
                });
                this.dispatchEvent(evt);

            });
    }
}