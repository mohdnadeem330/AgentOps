import { LightningElement, wire, track, api } from 'lwc';
import getServiceAppointments from '@salesforce/apex/Com_MultipleSPCreationCntrl.createMultipleAppointments';

import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import SP_OBJECT from "@salesforce/schema/ServiceAppointment";

import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

export default class Com_multiServiceAppointmentList extends LightningElement {

    @api accountId = '001FV000007DCNdYAO';
    @api classScheduleId = '02iFV000000YXUcYAO';
    @api optionalAttendee = [];
    @api appointmentListJson;
    @api remianingSlotJson;
    appointmentList = [];
    optionalAttendees = [];
    appointmentListInsert = [];
    
    
    resourceObj = {};
    territotyObj;
    territoryMemberObj;
    territoryTypeObj;
    accObj;
    jeopardyOptions = [];
    selectedReason = '';
    appointmentAddress;
    showTemplate = false;
    showSpinner = false;
    showErrorMessage = false;
    errorMessage = '';

    @track selectedResourceRecords = [];

    @wire(getPicklistValuesByRecordType, { objectApiName: 'ServiceAppointment', recordTypeId: '012FV000000CiBKYA0' })
    picklistValues({error, data}){
    	if(data){
            console.log('Picklist values');
        	console.log(data.picklistFieldValues.FSL__InJeopardyReason__c.values);
            var newOptions = [];
            setTimeout(() => {
                data.picklistFieldValues.Status.values.forEach(function(picklistRecord){
                    newOptions.push({label:picklistRecord.label , value : picklistRecord.label });
                });

                this.jeopardyOptions = newOptions;
            }, 1000);
        }else if(error){
        	console.log(error);
        }
    }

    connectedCallback() {
        console.log(this.classScheduleId);
        getServiceAppointments({accountId: this.accountId, classScheduleId : this.classScheduleId , optionalAttendee : this.optionalAttendee})
        .then(data => {
            var tempAppointmentList = [];
            if(data){
                if(data.insufficientSlots){
                    this.showErrorMessage = true;
                    this.errorMessage = 'Sufficient Slots are not available!';
                }else{
                    console.log('data');
                    console.log(data);
                    this.resourceObj = data.resourceObj;
                    this.territoryMemberObj = data.territoryMemberObj;
                    this.territoryTypeObj = data.territoryTypeObj;
                    this.accObj = data.accObj;
                    this.appointmentAddress = data.appointmentList[0].Address;
                    this.optionalAttendees = data.optionalAttendees;

                    data.appointmentList.forEach(function(record){
                        var appRecord = JSON.parse(JSON.stringify(record));
                        const startDate = new Date(record.SchedStartTime);
                        const endDate = new Date(record.SchedEndTime);

                        appRecord.startTimeString = startDate.toLocaleDateString(undefined, {day: 'numeric', month: 'long', year: 'numeric', hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Asia/Dubai"});
                        appRecord.endTimeString = endDate.toLocaleDateString(undefined, {day: 'numeric', month: 'long', year: 'numeric', hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Asia/Dubai"});

                        tempAppointmentList.push(appRecord);
                    });

                    this.appointmentList = tempAppointmentList;
                    this.appointmentListInsert = data.appointmentList;
                    this.appointmentListJson = JSON.stringify(this.appointmentListInsert || []); 
                    this.remianingSlotJson = JSON.stringify(data.remainingSlots || []);
                    this.dispatchEvent(new FlowAttributeChangeEvent('appointmentListJson', this.appointmentListJson, 'remianingSlotJson' , this.remianingSlotJson)); 
                    this.showTemplate = true;

                    console.log('tempAppointmentList');
                    console.log(tempAppointmentList);    
                }
            }
            
        })
        .catch(error => {
            console.log('Errorured:- ');
            console.log(error);
            this.showSpinner = false;
        });
    }

    handleResourceSearch(event){
        const searchTerm = event.target.value;
    }

    handleselectedResourceRecords(event) {
        this.selectedResourceRecords = [...event.detail.selRecords]
    }

    handleReasonChange(event){
        this.selectedReason = event.detail.value;
    }

    handleSubmit(event){
        this.showSpinner = true;
        /*createServiceAppointments({appointmentList : this.appointmentListInsert, optionalAttendees : this.optionalAttendees})
        .then(result => {
            this.showSpinner = false;
            this.showSuccessMessage = true;
            this.showTemplate = false;
        })
        .catch(error => {
            console.log('Errorured:- '+JSON.stringify(error));
            this.showSpinner = false;
            this.showSuccessMessage = false;
            this.showTemplate = true;
        });*/
    }

    handleSubjectChange(event){
        console.log(event.detail.value);
    }

    handleDescriptionChange(event){
        console.log(event.detail.value);
    }

    disconnectedCallback() {
        this.classScheduleId = '';
    }

}