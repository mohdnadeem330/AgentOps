import { LightningElement, api, track, wire } from 'lwc';
import retriveAppointmentData from '@salesforce/apex/Com_ServiceAppointmentSearch.fetchServiceAppointments';
import getStatusOptions from '@salesforce/apex/Com_ServiceAppointmentSearch.getStatusOptions';
import updateAppointments from '@salesforce/apex/Com_ServiceAppointmentSearch.updateAppointmentsList';
import LightningDatatable from 'lightning/datatable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PRODUCT_OBJECT from "@salesforce/schema/Product2";
import ASSET_OBJECT from "@salesforce/schema/Asset";
import APPOINTMENT_OBJECT from "@salesforce/schema/ServiceAppointment";

import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';



//import picklistColumn from './picklistColumn.html';
//import pickliststatic from './pickliststatic.html';
const columns = [
    { label: 'Name', fieldName: 'AppointmentLink', editable: false, type: 'url', typeAttributes: { label: { fieldName: 'AppointmentNumber' }, target: '_blank' } },
    { label: 'Account', fieldName: 'AccountName', editable: false },
    { label: 'Contact', fieldName: 'ContactName', editable: false },
    { label: 'Project', fieldName: 'CommunityName', editable: false },
    { label: 'Unit', fieldName: 'UnitName', editable: false },
    { label: 'Building', fieldName: 'BuildingName', editable: false },
    { label: 'Location', fieldName: 'LocationName', editable: false },
    { label: 'Appointment Type', fieldName: 'AppointmentType', editable: false, wrapText: true},
    { label: 'Class/Amenity', fieldName: 'ParentName', editable: false, wrapText: true},
    {
        label: "Start Time",
        fieldName: "startTimeString",
        wrapText: true,
    },
    {
        label: "End Time",
        fieldName: "endTimeString",
        wrapText: true,
    },
    { label: 'Status', fieldName: 'Status', editable: false },
    { label: 'Attended', fieldName: 'Com_Attended__c', editable: false },
    { label: 'Created By', fieldName: 'CreatedByName', editable: false },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Cancel Booking', name: 'cancel' },
                { label: 'Mark Attendance', name: 'attendance' },
            ]
        }
    }
];

export default class Com_AmenityServiceAppointment_List extends LightningElement(LightningDatatable ) {

    @track selectedProjectRecords = [];
    @track selectedBuildingRecords = [];
    @track selectedUnitRecords = [];
    @track selectedAccountRecords = [];
    @track selectedAmenityRecords = [];
    @track selectedClassRecords = [];
    @track selectedRecordsLength;
    customerEmail = '';
    appointmentNumber = '';
    showSpinner = true;
    showDataCard = false;
    showDataTable = false;
    showNoDataText = false;
    rowOffset = 0;
    draftValues = [];
    columns = columns;
    statusOptions = [];
    isShowModal=false;
    questionMessage = '';
    isButtonDisabled = true;
    showAttendanceOption = false;
    selectedAttendance = '';
    selectedStatus = '';
    selectedStartDate = '';
    selectedEndDate = '';
    showTableButtons = false;
    selectedDateRange = '';
    showStartEndDateOptions = false;
    selectedAppointmentType = '';
    showAssetLookup = false;
    showProductLookup = false;

    communityRecordTypeId;

    @track appointmentRecords = [];
    @track paginatedData = [];
    currentPage = 1;
    pageSize = 10;
    totalPages = 0;

    @track objectInfo;

    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    assetObjectInfo;

    @wire(getObjectInfo, { objectApiName: APPOINTMENT_OBJECT })
    wiredObjectInfo({error, data}) {
    if (error) {
        // handle Error
    } else if (data) {
        const rtis = data.recordTypeInfos;
        this.communityRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Community Appointments');
    }
    };

    get recordClassTypeId() {
        if(this.objectInfo.data) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Class");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get recordAmenityTypeId() {
        if(this.assetObjectInfo.data) {
            const rtis = this.assetObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Amenity");
        }else{
            return {}; // An empty mapping for now...
        }
    }

    get appointmentTypeOptions(){
        return [
            { label: 'Choose Appointment Type...', value: '' },
            { label: 'Amenity Appointment', value: 'Amenity Appointment' },
            { label: 'Class Appointment', value: 'Class Appointment' },
        ];
    }

    @wire(getStatusOptions)
    getStatusOptions({ error, data }) {
        if (data) {
            this.statusOptions = data;
        } else if (error) {
            this.showToast('Error', 'Error loading industry options', 'error');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: 'ServiceAppointment', recordTypeId: "$communityRecordTypeId" })
    picklistValues({error, data}){
    	if(data){
            console.log('Picklist values');
        	console.log(data.picklistFieldValues.Status.values);
            var newOptions = [];
            setTimeout(() => {
                data.picklistFieldValues.Status.values.forEach(function(picklistRecord){
                    newOptions.push({label:picklistRecord.label , value : picklistRecord.label });
                });

                this.statusOptions = newOptions;
                this.showSpinner = false;
            }, 1000);
        }else if(error){
        	console.log(error);
        }
    }

    get dateRangeOptions() {
        return [
            { label: 'Choose Range...', value: '' },
            { label: 'Current Week', value: 'Current Week' },
            { label: 'Last Week', value: 'Last Week' },
            { label: 'Next Week', value: 'Next Week' },
            { label: 'Current Month', value: 'Current Month' },
            { label: 'Last Month', value: 'Last Month' },
            { label: 'Next Month', value: 'Next Month' },
            { label: 'Custom', value: 'Custom' },
        ];
    }
    
    handleselectedProjectRecords(event) {
        this.selectedProjectRecords = [...event.detail.selRecords]
    }

    handleselectedBuildingRecords(event) {
        this.selectedBuildingRecords = [...event.detail.selRecords]
    }

    handleselectedUnitRecords(event) {
        this.selectedUnitRecords = [...event.detail.selRecords]
    }

    handleselectedAccountRecords(event) {
        this.selectedAccountRecords = [...event.detail.selRecords]
    }

    handleEmailChange(event) {
        this.customerEmail = event.detail.value;
    }

    handleAppointmentNumberChange(event) {
        this.appointmentNumber = event.detail.value;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleAppointmentTypeChange(event) {
        this.selectedAppointmentType = event.detail.value;

        if(event.detail.value == 'Amenity Appointment'){
            this.showAssetLookup = true;
            this.showProductLookup = false;
            
            this.selectedClassRecords = [];
        }else if(event.detail.value == 'Class Appointment'){
            this.showAssetLookup = false;
            this.showProductLookup = true;

            this.selectedAmenityRecords = [];
        }else{
            this.showAssetLookup = false;
            this.showProductLookup = false;

            this.selectedClassRecords = [];
            this.selectedAmenityRecords = [];
        }
    }

    handleselectedAmenityRecords(event) {
        this.selectedAmenityRecords = [...event.detail.selRecords];
    }

    handleselectedProductRecords(event) {
        this.selectedClassRecords = [...event.detail.selRecords];
    }

    handleStartDateChange(event){
        this.selectedEndDate = event.detail.value;
    }

    handleEndDateChange(event){
        this.selectedStartDate = event.detail.value;
    }

    handleDateRangeChange(event){
        console.log(event.detail.value);
        this.selectedDateRange = event.detail.value;

        if(event.detail.value == 'Custom'){
            this.showStartEndDateOptions = true;
        }else{
            this.showStartEndDateOptions = false;
        }
    }

    handleSearchClick(){
        this.showSpinner = true;
        this.showDataCard = false;
        

        retriveAppointmentData({projectList: this.selectedProjectRecords, buildingList : this.selectedBuildingRecords, unitList : this.selectedUnitRecords, accountList : this.selectedAccountRecords, amenityList : this.selectedAmenityRecords, classList: this.selectedClassRecords, email : this.customerEmail, bookingNumber: this.appointmentNumber, status: this.selectedStatus, startDate : this.selectedStartDate, endDate : this.selectedEndDate, selectedDateRange : this.selectedDateRange, selectedAppointmentType : this.selectedAppointmentType})
        .then(result => {
            console.log('result');
            console.log(result);
            if(result.length > 0){
                this.appointmentRecords = result;
                
                this.appointmentRecords.forEach(record => {

                    console.log(record.Id+'-'+record.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c);

                    record.AppointmentLink = '/' + record.Id;
                    record.CommunityName = record.Community__c ? record.Community__r.Name : '';
                    record.UnitName = record.Asset__c ? record.Asset__r.Name : '';
                    record.BuildingName = record.Precinct__c ? record.Precinct__r.Name : '';
                    record.LocationName = record.ServiceTerritoryId ? record.ServiceTerritory.Name : '';
                    record.CreatedByName = record.CreatedById ? record.CreatedBy.Name : '';
                    record.AccountName =  record.AccountId ? record.Account.Name : '';
                    record.ContactName =  record.ContactId ? record.Contact.Name : '';

                    const startDate = new Date(record.SchedStartTime);
                    const endDate = new Date(record.SchedEndTime);

                    record.startTimeString = startDate.toLocaleDateString(undefined, {day: 'numeric', month: 'long', year: 'numeric', hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Asia/Dubai"});
                    record.endTimeString = endDate.toLocaleDateString(undefined, {day: 'numeric', month: 'long', year: 'numeric', hour: "numeric", minute: "2-digit", hour12: true, timeZone: "Asia/Dubai"})

                    if(record.FSSK__FSK_Assigned_Service_Resource__c != null && record.FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName == 'Amenity'){
                        record.AppointmentType =  'Amenity Appointment';
                        record.ParentName = record.FSSK__FSK_Assigned_Service_Resource__r.Asset.Name;
                    }else{
                        record.AppointmentType = 'Class Appointment';
                        if(record.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c != null && record.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c != undefined){
                            record.ParentName = record.FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Name;
                        }else{
                            record.ParentName = '';
                        }
                    }
                });


                this.totalPages = Math.ceil(result.length / this.pageSize);
                this.updatePaginatedData();

                this.showSpinner = false;
                this.showDataCard = true;
                this.showDataTable = true;
                this.showNoDataText = false;
            }else{
                this.showSpinner = false;
                this.showDataCard = true;
                this.showDataTable = false;
                this.showNoDataText = true;
            }
            
        }).catch(error => {
            console.log(error);
        });
    }

    updatePaginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedData = this.appointmentRecords.slice(start, end);
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    handleSave(event) {
        var self = this;
        this.isShowModal = false;
        this.showSpinner = true;
        var selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        updateAppointments({ appointmentList: selectedRows, selectedAttendance : this.selectedAttendance })
        .then(() => {
            
            this.handleSearchClick(); // Refresh table
        })
        .catch(error => {
            console.error('Error updating attendance:', error);
            this.showSpinner = false;
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        var selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('actionName=>'+actionName);
        console.log("getSelectedRows => ", selectedRows.length);

        if(selectedRows.length > 0){
            switch (actionName) {
                case 'cancel':
                    this.isShowModal = true;
                    this.questionMessage = 'Do you want to cancel the selected Bookings?';
                    this.isButtonDisabled = false;
                    break;
                case 'attendance':
                    this.isShowModal = true;
                    this.showAttendanceOption = true;
                    this.questionMessage = 'Do you want to mark attendance for selected Bookings?';
                    break;
                default:
                    break;
            }
        }else{
            console.log('inside else');
            const event = new ShowToastEvent({
                title: 'Warning!',
                message: 'Please select any row(s) to proceed!',
                variant: 'warning',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }
    }

    handleRowSelection(event){
        var selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();


        if(selectedRows.length > 0){
            this.showTableButtons = true;
        }else{
            this.showTableButtons = false;
        }
        
    }

    handleTableButtonAction(event){
        var buttonName = event.target.name;

        console.log(buttonName);

        switch (buttonName) {
            case 'cancel':
                this.isShowModal = true;
                this.questionMessage = 'Do you want to cancel the selected Bookings?';
                this.isButtonDisabled = false;
                break;
            case 'attendance':
                this.isShowModal = true;
                this.showAttendanceOption = true;
                this.questionMessage = 'Do you want to mark attendance for selected Bookings?';
                break;
            default:
                break;
        }
    }

    hideModalBox() {  
        this.isShowModal = false;
        this.isButtonDisabled = true;
        this.showAttendanceOption = false;
    }
    
    get options() {
        return [
            { label: 'choose option...', value: '' },
            { label: 'Present', value: 'Present' },
            { label: 'Absent', value: 'Absent' },
        ];
    }

    handleAttendanceChange(event) {
        this.selectedAttendance = event.detail.value;

        if(this.selectedAttendance  == 'Present' || this.selectedAttendance  == 'Absent'){
            this.isButtonDisabled = false;
        }else{
            this.isButtonDisabled = true;
        }
    }
}