import { LightningElement,api, wire, track} from 'lwc';
import { getPicklistValues, getObjectInfo} from 'lightning/uiObjectInfoApi';
import getAllProjects from '@salesforce/apex/AppointmentController.getAllProjects';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBuyerData from '@salesforce/apex/AppointmentController.getBuyerData';
import getUserData from '@salesforce/apex/AppointmentController.getUserData';
import getResidencePicklist from '@salesforce/apex/AppointmentController.getResidencePicklist';
import getEmiratesPicklist from '@salesforce/apex/AppointmentController.getEmiratesPicklist';
import getNationalitiesPicklist from '@salesforce/apex/AppointmentController.getNationalitiesPicklist';
import bookingOnBehalf from '@salesforce/customPermission/EnableAppointMentBookingOnBehalf';
import getCountyCodePicklist from '@salesforce/apex/AppointmentController.getCountyCodePicklist';
import loggedInUserId from '@salesforce/user/Id';
import hasFutureAppoitment from '@salesforce/apex/AppointmentController.hasFutureAppoitment';
import getProjectLocations from '@salesforce/apex/AppointmentController.getProjectLocations';
import getAvailableDates from '@salesforce/apex/AppointmentController.getAvailableDates';
import getAvailableTimeSlots from '@salesforce/apex/AppointmentController.getAvailableTimeSlots';
import bookAppointment from '@salesforce/apex/AppointmentController.bookAppointment';
import cancelAppointment from '@salesforce/apex/AppointmentController.cancelBookedAppointment';
import CancellationReasonPicklist from '@salesforce/apex/AppointmentController.getCancellationReasonPicklist';
import ConvertLeadFromAppointment from '@salesforce/label/c.ConvertLeadFromAppointment';
import convertLead from '@salesforce/apex/AppointmentController.convertLead';
import getCustPresencePicklist from '@salesforce/apex/AppointmentController.getCustomerPresencePicklist';
// Added By Moh Sarfaraj
import maskAnyString from '@salesforce/apex/BrokerLeadController.maskAnyString';

//START - Cancel Existing Appointment-SARAN
const PROCEED_TO_CANCEL_OK = 'Yes';
const CLOSE_X = 'No';
const BOOKING_SUCCESSFULL='Booking Successful';
const APPOINTMENT_BOOKING_SUCCESSFULL = 'Your appointment is booked successfully!';
const BOOKING_FAILED='Booking Failed';
const APPOINTMENT_BOOKING_FAILED='Booking Failed ';
const CANCEL_SUCCESSFULL='Booking Cancelled Successful';
const APPOINTMENT_CANCEL_SUCCESSFULL='Your Existing Booking has been Cancelled Successfully';
const CANCEL_FAILED='Booking Cancellation Failed';
const APPOINTMENT_CANCEL_FAILED='Booking Cancellation Failed ';
//END - Cancel Existing Appointment-SARAN

export default class AppointmentBookingModal extends LightningElement {


   
    /* @api leadId='00Q2600000FgEBVEA3';
    @api opportunityId;
    @api contactId;*/
    @api recordId;
    sObjectRecordType;
    @api userId=loggedInUserId;
    @track showSpinner;
    nationalities;
    residencies;
    emirates;
    appointmentId;
    userRecord;
    buyerDetails;
    projects;
    selectedProject;
    selectedProjectLabel;
    locations;
    selectedLocation;
    dates;
    selectedDate;
    slots;
    selectedSlot;
    showEmirates=false;
    RESIDENTVAL='Resident';
    isLoading=false;
    activeSections=['AppointmentDetails'];
    disableBooking = false;
    countyCodeValues;
    customerPresenceOptions;

    //START - Cancel Existing Appointment-SARAN
    askConfirmation = false;
    inputObj = {}; //Generic obj to pass values to confirm modal comp
    xx_modal_class = 'aldar-modal slds-modal slds-fade-in-open xx_confirm_open';//xx_confirm_open;
    cancelReason = null;
    cancelComment = null;
    appointmentRec = {};
    forExistingAppointment = [];
    selectedLocationValue = null;
    cancellationReason;
    //END - Cancel Existing Appointment-SARAN
    numberOfBedroomsSelected = '';

    // Added by Moh Sarfaraj for ASF-1998
    isRanTimeSlotAPI = false;
    isRanDateAPI = false;
    isLeadConverted = false;

    // Added By Moh Sarfaraj
    buyerMaskEmail; buyerMaskMobile;

    /* Added by Tharun as per BPE-261 */
    @wire(getCustPresencePicklist )
    wiredCustPresencePicklist({ error, data }) {
        if (data) {
            this.customerPresenceOptions = data;
        } else if (error) {
            this.customerPresenceOptions = undefined;
        }
    }
    /* Added by Tharun as per BPE-261 */

    @wire(getCountyCodePicklist )
    wiredCountyCodePicklist({ error, data }) {
        if (data) {
            this.countyCodeValues = data;
            
        } else if (error) {
            this.countyCodeValues = undefined;
        }
    }
    @wire(getNationalitiesPicklist)
    wiredNAtionalityPicklist({ error, data }) {
        if (data) {
            this.nationalities = data;
            
        } else if (error) {
            this.nationalities = undefined;
        }
    }

    @wire(getResidencePicklist)
    wiredRecidencyPicklist({ error, data }) {
        if (data) {
            this.residencies = data;
            
        } else if (error) {
            this.residencies = undefined;
        }
    }

    @wire(getEmiratesPicklist)
    wiredEmiratesPicklist({ error, data }) {
        if (data) {
            this.emirates = data;
            
        } else if (error) {
            this.emirates = undefined;
        }
    }
    @wire(getAllProjects)
    wiredPROJECTPicklist({ error, data }) {
        if (data) {
            if(data.length == 0) {
                data = [{label:'No Value', value:'No Value'}];
            }
            this.projects = data;
            console.log('pr Data ');
            console.log(data);
        } else if (error) {
            this.projects = undefined;
        }
    }

    @wire(CancellationReasonPicklist)
    wiredCancellationReasonPicklist({ error, data }) {
        if (data) {
            //this.cancellationReason = data;
            let newOptions = [];
            for(let i in data) {
                newOptions.push({label:data[i].label, value:data[i].label});
            }
            this.cancellationReason = null;
            this.cancellationReason = newOptions;

            
        } else if (error) {
            this.cancellationReason = undefined;
        }
    }

    get bookOnBehalf() {
        return bookingOnBehalf;    
    }
        
        
    get dates(){
        var valueToReturn=[];
        for(var key in this.dateTimeSlotData){
            valueToReturn.push({ label: key, value: key });
        }
        return valueToReturn;
    }
    get timeslots(){
        var valueToReturn=[];
        if(this.selectedDate){
            for(var key in this.dateTimeSlotData[this.selectedDate]){
                valueToReturn.push({ label: key, value: this.dateTimeSlotData[this.selectedDate][key] });
            }
        }
        return valueToReturn;
    }
    connectedCallback(){
        this.isLoading=true;
        this.initRecords();
        this.checkForTheExistingAppointment();
    }
    
    checkForTheExistingAppointment() {
        this.isLoading=true;
        hasFutureAppoitment({recordId:this.recordId})
        .then(result => {
            if(result.length!=0) {
                this.appointmentRec = result[0];
                this.disableBooking = result.length!=0;
            } else {
                this.disableBooking = false;
                this.appointmentRec = {};
            }
            this.isLoading=false;
        })
        .catch(error => {
            // TODO Error handling
            console.log('ABM-ERR -> ',error);
            this.isLoading=false;
        });
    }
    
    initRecords(){
        this.showSpinner = true;
        if(this.recordId){
            getBuyerData({ recordId: this.recordId })
            .then(data => {
                for(var key in data){
                    this.sObjectRecordType = key;
                    this.buyerDetails = data[key];
                }
                this.showEmirates=(this.buyerDetails.residence == this.RESIDENTVAL);
                this.numberOfBedroomsSelected = this.buyerDetails.numberOfBedrooms;
                //this.userId=loggedInUserId;

                // Added By Moh Sarfaraj starts
                this.getMaskedEmail();
                this.getMaskedMobile();
                // Added By Moh Sarfaraj end

                this.initUserRecords();
            }).catch(error => {
                this.buyerDetails = undefined;
                this.isLoading=false;
                this.showSpinner = false;
            })
        }else{
            this.isLoading=false;
            this.showSpinner = false;
        }
        this.showSpinner = false;
    }

    initUserRecords(){   
        if(this.userId){
            getUserData({ recordId: this.userId })
            .then(data => {
                this.userRecord = data;
                console.log(this.userRecord);
                console.log(JSON.stringify(this.userRecord));
                this.isLoading=false;
            }).catch(error => {
                this.userRecord = undefined;
                this.isLoading=false;
            })
        }else{
            this.isLoading=false;
        }    
    }

    // Added By Moh Sarfaraj starts
    getMaskedEmail(){
        maskAnyString({
            emailAddress : this.buyerDetails.email
        }).then(results=>{
            this.buyerMaskEmail = results; 
        }).catch(error=>{})
    }

    getMaskedMobile(){
        maskAnyString({
            emailAddress : this.buyerDetails.mobile
        }).then(results=>{
            this.buyerMaskMobile = results;
        }).catch(error=>{})
    }
    // Added By Moh Sarfaraj end

    handleUserIDChange(event){
        this.isLoading=true;
        this.userId = event.target.value;
        this.selectedProject=undefined;
        this.selectedProjectLabel=undefined;
        this.locations = undefined;
        this.selectedLocation=undefined;
        this.dates=undefined;
        this.selectedDate=undefined;
        this.slots=undefined;
        this.selectedSlot=undefined;
        this.initUserRecords();
    }

    handleResidencyChange(event){
        this.showEmirates=(event.detail.value == this.RESIDENTVAL);
    }

    handleProjectChange(event){
        this.isLoading=true;
        this.selectedProject=event.detail.value;
        for (let index = 0; index < this.projects.length; index++) {
            const p = this.projects[index];
            if(p.value == this.selectedProject){
                this.selectedProjectLabel = p.label;
            }   
        }
        //reset filters below
        //this.template.querySelector(".bookingConfirmationWinReason").value=undefined;
        this.locations = undefined;
        this.selectedLocation=undefined;
        this.dates=undefined;
        this.selectedDate=undefined;
        this.slots=undefined;
        this.selectedSlot=undefined;
        this.isRanTimeSlotAPI = false;
        this.isRanDateAPI = false;

        // Added by Moh Sarfaraj for ASF-1998
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            if(each.name === 'locationId' || each.name === 'bookingDate' || each.name === 'slotId'){
                each.value = null;
            }
        });

        getProjectLocations({ userRecord: this.userRecord,projectId : this.selectedProject })

        .then(data => {
            console.log('data -> ',data);
            this.locations = data;
            this.isLoading=false;
            

        }).catch(error => {
            this.locations = undefined;
            this.isLoading=false;
        })
    }

    async handleLocationChange(event){
        this.isRanTimeSlotAPI = false;
        this.isLoading=true;
        this.selectedLocation=event.detail.value;
        this.selectedLocationValue = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.dates=undefined;
        this.selectedDate=undefined;
        this.slots=undefined;
        this.selectedSlot=undefined;
        this.isRanDateAPI = false;
        
        await getAvailableDates({ userRecord: this.userRecord, projectId : this.selectedProject, locationId:this.selectedLocation})
        .then(data => {
            if(data == undefined || data.length == 0 || data == null){
                const evt = new ShowToastEvent({
                    title: 'No Date Slot',
                    message: 'There are no more dates available.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                this.isRanDateAPI = true;
            }else
            {
            this.dates = data;
            this.isLoading=false;
            this.isRanDateAPI = true;
            }
        }).catch(error => {
            const evt = new ShowToastEvent({
                title: 'No Date Slot',
                message: 'There are no more dates available..',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            this.dates = undefined;
            this.isLoading=false;
            this.isRanDateAPI = true;
        })
    }

    async handleDateChange(event){
        this.isRanTimeSlotAPI = false;
        this.isLoading=true;
        this.selectedDate=event.detail.value;
        this.slots=undefined;
        this.selectedSlot=undefined;

        await getAvailableTimeSlots({ userRecord: this.userRecord, projectId : this.selectedProject, locationId:this.selectedLocation,selectedDate : this.selectedDate })
        .then(data => {

            // Tharun Added - Check if data contains a Message parameter indicating an error
            if (data && data[0].hasOwnProperty('Message')) {
                console.error('Error message:', data[0].Message);
                this.slots = undefined;
                this.isLoading = false;
                this.showToast('No Time Slot', data[0].Message, 'error');
            } else if(data == undefined || data.length == 0 || data == null){
                this.showToast('No Time Slot', 'There are no more time slots available.', 'error');
                this.isLoading = false;
                this.isRanTimeSlotAPI = true;
            }else {
                // Assuming data is correct and slots are available
                this.slots = data;
                this.isLoading = false;
                this.isRanTimeSlotAPI = true;
            }
        }).catch(error => {
            const evt = new ShowToastEvent({
                title: 'No Time Slot',
                message: 'There are no more time slots available..',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            this.slots = undefined;
            this.isLoading=false;
            this.isRanTimeSlotAPI = true;
        })
    }

    handleSubmit(){
        //Validate
        //Callout
        //Create record
        var isError = false;
        // Added by Moh Sarfaraj for ASF-1998
        let isHavingTimeSlot = true;
        let isHavingDateSlot = true;
       
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value ){
                // Added by Moh Sarfaraj for ASF-1998
                if(element.name === 'bookingDate' && this.isRanDateAPI && (!this.dates || this.dates === undefined || this.dates === null || this.dates === '')){
                    const evt = new ShowToastEvent({
                        title: 'No Date Slot',
                        message: 'Sorry, there is no more dates available.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    isHavingDateSlot = false;
                }else 
                if(element.name === 'slotId' && this.isRanTimeSlotAPI && (!this.slots || this.slots === undefined || this.slots === null || this.slots === '')){
                    const evt = new ShowToastEvent({
                        title: 'No Time Slot',
                        message: 'Sorry, there is no more slots available.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    isHavingTimeSlot = false;
                }
                else{
                    isError = true;
                }    
            }
        });
        if(!isHavingTimeSlot || !isHavingDateSlot){
            return;
        }
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value ){
                isError =true;
                this.activeSections=['UserDetails','BuyerDetails','AppointmentDetails'];
            }
        });

        if(isError){
            const evt = new ShowToastEvent({
                title: 'Reqired Fields Missing',
                message: 'Please populate all the fields before submitting',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }else{
            this.isLoading=true;
            var objectToReturn = {};
            this.template.querySelectorAll('.bookingDetails').forEach(element => {
                objectToReturn[element.name] =  element.value;
                if(element.dataset.labelName){
                    objectToReturn[element.dataset.labelName] =  element.options.find(opt => opt.value === element.value).label;;
                }
            });
            console.log(objectToReturn);
            //objectToReturn['leadId'] = this.recordId;
            objectToReturn['recordId'] = this.recordId;
            objectToReturn['numberOfBedrooms'] = this.numberOfBedroomsSelected;
            objectToReturn['selectedLocationValue'] = this.selectedLocationValue;
            // Added by Moh Sarfaraj
            objectToReturn['phone'] = this.buyerDetails.mobile;
            objectToReturn['email'] = this.buyerDetails.email;
            
            bookAppointment({ userRecord: this.userRecord, projectId : this.selectedProject, requestInnerMap:objectToReturn })
            .then(data => {
                console.log(data);
                if(data=='success'){
                    console.log(ConvertLeadFromAppointment);
                    let inclusiveProjectsArr = ConvertLeadFromAppointment.split(',').map(e => e.trim().toUpperCase());
                    if(inclusiveProjectsArr.includes(this.selectedProjectLabel.trim().toUpperCase())){
                        this.handleLeadConversion();
                    }else{
                        const evt = new ShowToastEvent({
                            title: BOOKING_SUCCESSFULL,
                            message: APPOINTMENT_BOOKING_SUCCESSFULL,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        this.disableBooking = true;
                        this.closeModal();
                        this.isLoading=false;
                    }
                }else{
                    const evt = new ShowToastEvent({
                        title: BOOKING_FAILED,
                        message: APPOINTMENT_BOOKING_FAILED+'-'+data,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                }
            }).catch(error => {
                console.log(JSON.stringify(error));
                const evt = new ShowToastEvent({
                    title: BOOKING_FAILED,
                    message: APPOINTMENT_BOOKING_FAILED+'-'+error.body.message, //JSON.stringify(error),
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.isLoading=false;
            })
        }
        
    }

    handleLeadConversion(){
        convertLead({ recordId: this.recordId })
        .then(data => {
            console.log(data);
            if(data=='success'){
                this.isLeadConverted = true;
            }else{
            }
        }).catch(error => {
            console.log(JSON.stringify(error));
        }).finally( () => {
            const evt = new ShowToastEvent({
                title: BOOKING_SUCCESSFULL,
                message: APPOINTMENT_BOOKING_SUCCESSFULL,
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            this.disableBooking = true;
            this.closeModal();
            this.isLoading=false;
        })
    }
    
    //START - Cancel Existing Appointment-SARAN
    handleCancelAppointment(event) {
        
        if(this.askConfirmation) {
            this.inputObj = {};
            this.askConfirmation = false;
            if(event.detail.accepted) {
                this.handleCancelExisting(event);
            }
            if(event.detail.declined) {                
                this.cancelReason = null;
                this.cancelComment = null;
                //Just close the modal
            }
            return true;
        }

        if(!this.askConfirmation) {
            this.askConfirmation = true;
            let inputObj = {};
            inputObj.appointmentId = this.appointmentRec.AppointmentId__c; //Pass the Appointment__c Id
            inputObj.modalHeader = 'Do you want to Cancel this appointment?'; //Pass the header with more information
            inputObj.modalContent = '#'+this.appointmentRec.AppointmentId__c+' on '+this.appointmentRec.Date__c+' '+this.appointmentRec.Appointment_Slot_Time__c; //Date & Time to cancel the appointment
            inputObj.accepted = false;
            inputObj.declined = false;
            inputObj.acceptBtnLabel = PROCEED_TO_CANCEL_OK;
            inputObj.cancelBtnLabel = CLOSE_X;
            inputObj.dynamicClass = this.xx_modal_class;
            this.inputObj = inputObj; //Pass this to the Confirm Modal window to get the confirmation
        }
    }

    handleCancelReason(event) {
        const field = event.target.name;
        if (field === 'cancel_reason') {
            this.cancelReason = event.target.value;
        } else if (field === 'cancel_comment') {
            this.cancelComment = event.target.value;
        }
    }
    handleCancelExisting(event){
        //Validate
        //Callout
        //Update record // Cancel the Appointment
        
        this.isLoading=true;
        var objectToReturn = {};
        objectToReturn['cancelreason'] = this.cancelReason;
        objectToReturn['message'] = this.cancelComment;
        console.log(objectToReturn);
        cancelAppointment({ recordId: this.recordId, requestInnerMap:objectToReturn })
        .then(data => {
            if(data=='success'){
                this.checkForTheExistingAppointment();
                const evt = new ShowToastEvent({
                    title: CANCEL_SUCCESSFULL,
                    message: APPOINTMENT_CANCEL_SUCCESSFULL,
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                //this.disableBooking = true;
                //this.closeModal();
            } else{
                const evt = new ShowToastEvent({
                    title: CANCEL_FAILED,
                    message: APPOINTMENT_CANCEL_FAILED+data,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            this.isLoading=false;
        }).catch(error => {
                const evt = new ShowToastEvent({
                title: CANCEL_FAILED,
                message: APPOINTMENT_CANCEL_FAILED+JSON.stringify(error),
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
        })        
    }
    //END - Cancel Existing Appointment-SARAN
    
    closeModal(){
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false, refresh:this.isLeadConverted}}));
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
}