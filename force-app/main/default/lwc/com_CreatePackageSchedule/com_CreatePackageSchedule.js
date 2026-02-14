import { LightningElement, api, track, wire } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PRODUCT_OBJECT from "@salesforce/schema/Product2";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import { NavigationMixin } from 'lightning/navigation';
import getParentClass from '@salesforce/apex/com_AmenityCreationCntrl.getParentClass';
import updateSchedule from '@salesforce/apex/com_AmenityCreationCntrl.updateClassSchedule';

import { CloseActionScreenEvent } from 'lightning/actions';export default class Com_CreatePackageSchedule extends LightningElement {
    @track objectInfo;
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    assetObjectInfo;

    showSpinner = false;
    showClassSchedule = true;
    remainingCount = 32768;
    showVatAmountFields = false;


    @api recordId;
    
    classId;
    classPackageList = [];
    classScheduleList = [];

    packageOptions = [];
    classPackage = '';
    @track classPackagesList = [];
    @track scheduleNamesList = [];

    keyIndex = 0;
    @track itemList = [
        {
            id: 0
        }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @wire(getParentClass,{packageId : '$recordId'})
    getParentClass({ error, data }) {
        if (data){
            this.classId = data.Com_Class__c;
        }else if (error) {
            console.log(JSON.stringify(error));
        }
    }

    get recordClassTypeId() {
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get recordClassPackageTypeId() {
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class Package");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get recordClassScheduleTypeId() {
        if(this.assetObjectInfo.data) {
            const rtis = this.assetObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class Schedule");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    connectedCallback() {
        console.log('from connectedcallback'+this.recordId);
    }

    

    handleClassScheduleSubmit(event) {
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

    handleClassScheduleSuccess(event) {
        console.log('handleClassScheduleSuccess');
        console.log(event.detail.id);

        updateSchedule({classId : this.classId, scheduleNamesList: this.scheduleNamesList, scheduleId : event.detail.id})
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.log('Errorured:- '+ JSON.stringify(error));
        });
    }

    handleTAndCChange(event){
        this.remainingCount = 32768 - parseInt(event.target.value.length);
    }

    
    handleVatIncludedChange(event){
        if(event.target.value == 'Yes'){
            this.showVatAmountFields = true;
        }else{
            this.showVatAmountFields = false;
        }
    }

    handleCommissionTypeChange(event){
        if(event.target.value == 'Percentage'){
            this.showCommissionPercentFields = true;
            this.showCommissionAmountFields = false;
        }else if(event.target.value == 'Amount'){
            this.showCommissionAmountFields = true;
            this.showCommissionPercentFields = false;
        }else{
            this.showCommissionPercentFields = false;
            this.showCommissionAmountFields = false;
        }
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

        if(showClassSchedule){
            this.classPackagesList.splice(event.target.accessKey, 1);
            this.scheduleNamesList.splice(event.target.accessKey, 1);
        }
    }

    handlePackageChange(event){
        this.classPackagesList[event.target.accessKey] = event.detail.value;
    }

    handleScheduleNameChange(event){
        this.scheduleNamesList[event.target.accessKey] = event.detail.value;
    }
}