import { LightningElement, api, track, wire } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import ASSET_OBJECT from "@salesforce/schema/Asset";
import createOperatingHours from '@salesforce/apex/com_AmenityCreationCntrl.createOperatingHourForAmenity';
import showUploadedFiles from '@salesforce/apex/com_AmenityCreationCntrl.getFiles';
import deleteUploadedFiles from '@salesforce/apex/com_AmenityCreationCntrl.deleteFiles';
import createTimeSlots from '@salesforce/apex/com_AmenityCreationCntrl.createTimeSlots';
import createDocuments from '@salesforce/apex/com_AmenityCreationCntrl.createDocuments';

export default class Com_Amenity_Asset_Create extends NavigationMixin(LightningElement) {
    assetId;
    unitTypes = ['Apartment','Sky Villa','Penthouse','Duplex','TownHouse','Store','Villa','Plot of land','Studio','Storage','PARKING SPACE'];
    
    @track objectInfo;
    @api projectId;
    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    objectInfo;
    assetId;
    showFileUploader = false;
    showSpinner = false;
    showProject= false;
    showAmountField = false;
    showVatAmountField = false;
    remainingCount = 32768;
    operatingHour;
    showTimeslotCreation = false;
    showAmenityCreation = true;
    filesList;
    showFilesSection = false;;

    keyIndex = 0;
    @track itemList = [
        {
            id: 0
        }
    ];

    get dayOfWeekValues() {
        return [
            { label: 'Sunday', value: 'Sunday' },
            { label: 'Monday', value: 'Monday' },
            { label: 'Tuesday', value: 'Tuesday' },
            { label: 'Wednesday', value: 'Wednesday' },
            { label: 'Thursday', value: 'Thursday' },
            { label: 'Friday', value: 'Friday' },
            { label: 'Saturday', value: 'Saturday' },
        ];
    }

    @track dayOfWeekList = [];
    @track startTimeList = [];
    @track endTimeList = [];
    errorMessage;
    showError = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            //it gets executed before the connected callback and avilable to use
            this.projectId = currentPageReference.state.recordId;
        }

        if(this.projectId != undefined) this.showProject = true;
        console.log('this.projectId'+this.projectId);
    }

    get recordTypeId() {
        // Returns a map of record type Ids
        console.log('this.objectInfo');
        console.log(this.objectInfo);
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Amenity");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.tiff'];
    }

    connectedCallback() {
        this.assetFilter = {
        criteria: [
                {
                    fieldPath: 'RecordType.DeveloperName',
                    operator: 'eq',
                    value: 'Ecss_unit',
                },
                {
                    fieldPath: 'ECSS_Unit_Type__c',
                    operator: 'nin',
                    value: this.unitTypes,
                },
            ],
            filterLogic: '1 AND 2',
        };
    }

    handleSuccess(event) {
        console.log('onsuccess event recordEditForm',event.detail.id);
        this.assetId = event.detail.id;
        
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if(inputFields){
            inputFields.forEach(field=>{
                field.reset();
            });
        }

        createOperatingHours({amenityId : event.detail.id})
        .then(result => {
            this.operatingHour = result;
            this.showFileUploader = true;
            this.showTimeslotCreation = true;
            this.showAmenityCreation = false;
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('Errorured:- '+JSON.stringify(error));
        });
    }
    
    handleSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Parent_Asset__c = this.assetId;
        fields.Com_Paid_Amenity__c = 'No';

        if(fields.Com_Paid_Amenity__c == 'Yes' && (fields.Weekdays_Amount__c == null || fields.Weekend_Amount__c == null || fields.Com_Amenity_Deposit_AED__c == null)){
            console.log('inside if');
            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'Weekday/Weekend Amount, Amenity Deposit (AED) is required when Amenity is Paid.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.showSpinner = false;
        }else{
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }        
    }

    handleError(event){
        console.log('onerror event recordEditForm');
        this.showSpinner = false;
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;

        console.log(uploadedFiles);

        showUploadedFiles({recordId : this.assetId})
        .then(data => {
            this.filesList = Object.keys(data).map(item=>({"label":data[item],
             "value": item,
             "url":`/sfc/servlet.shepherd/document/download/${item}`
            }))

            this.showFilesSection = true;
        })
        .catch(error => {
            console.log('Errorured:- '+error.body.message);
        });

        var documentIds = [];
        uploadedFiles.forEach(function(document){
            documentIds.push(document.documentId);
        });

        createDocuments({asseId : this.assetId, documentIdList : documentIds})
        .then(data => {
            console.log('documents created');
        })
        .catch(error => {
            console.log('Errorured:- '+error.body.message);
        });

        
    }

    handleSkipUploadClick(event){
        this.showFileUploader = false;
        this.showTimeslotCreation = true;
    }

    handlePaidAmenityChange(event){
        if(event.target.value == 'Yes'){
            this.showAmountField = true;
        }else{
            this.showAmountField = false;
            this.showVatAmountField = false;
        }
    }

    handleIncludeVatChange(event){
        if(event.target.value){
            this.showVatAmountField = true;
        }else{
            this.showVatAmountField = false;
        }
    }

    handleTAndCChange(event){
        this.remainingCount = 32768 - parseInt(event.target.value.length);
    }

    handleTimeSlotSubmit(event){
        this.showSpinner = true;
        event.preventDefault();       // stop the form from submitting
        var isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            isVal = isVal && element.reportValidity();
        });
        
        this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
            element.submit();
        });
    }

    handleTimeSlotSubmitSuccess(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.assetId,
                objectApiName: 'Asset',
                actionName: 'view'
            }
        });

        this.showAmenityCreation = true;
        this.showFileUploader = false;
        this.showTimeslotCreation = false;
        this.showSpinner = false;
    }

    addRow() {
        ++this.keyIndex;
        var newItem = [{ id: this.keyIndex }];
        this.itemList = this.itemList.concat(newItem);
    }

    removeRow(event) {
        if (this.itemList.length >= 2) {
            this.itemList = this.itemList.filter(function (element) {
                return parseInt(element.id) !== parseInt(event.target.accessKey);
            });
        }

        this.dayOfWeekList.splice(event.target.accessKey, 1);
        this.startTimeList.splice(event.target.accessKey, 1);
        this.endTimeList.splice(event.target.accessKey, 1);
    }

    previewHandler(event){
        console.log(event.target.dataset.id)
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }


    handleClassPackageSubmit(event) {
        this.showError = false;
        this.showSpinner = true;
        createTimeSlots({operatingHoursId : this.operatingHour.Id, daysOfweekList : this.dayOfWeekList, startTimeList : this.startTimeList, endTimeList: this.endTimeList,  assetId: this.assetId})
        .then(result => {
            console.log('result');
            this.showError = false;
            this.showSpinner = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetId,
                    objectApiName: 'Asset',
                    actionName: 'view'
                }
            });

            this.showAmenityCreation = true;
            this.showFileUploader = false;
            this.showTimeslotCreation = false;
            this.showSpinner = false;
        })
        .catch(error => {
            console.log('Errorured:- '+ JSON.stringify(error));
            console.log(error.body.fieldErrors);
            console.log(error.body.pageErrors);

            this.showSpinner = false;
            this.showError = true;
            this.errorMessage = 'Error occurred due to any of following issue:';
        });
    }

    handleNameChange(event) {
        console.log(event.detail.value);
        console.log(event.target.accessKey);
        
        this.dayOfWeekList[event.target.accessKey] = event.detail.value;
    }

    handleStartTimeChange(event) {
        console.log(event.detail.value);
        console.log(event.target.accessKey);
        this.startTimeList[event.target.accessKey] = event.detail.value;
    }

    handleEndTimeChange(event) {
        console.log(event.detail.value);
        console.log(event.target.accessKey);
        this.endTimeList[event.target.accessKey] = event.detail.value;
    }

    handleRecordChange(event){
        console.log('inside recordpicker'+event.detail.recordId);
        this.assetId = event.detail.recordId;
    }
}