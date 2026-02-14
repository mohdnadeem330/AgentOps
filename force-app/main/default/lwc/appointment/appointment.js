import { LightningElement,api, wire} from 'lwc';
import getAllProjects from '@salesforce/apex/AppointmentController.getAllProjects';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBuyerData from '@salesforce/apex/AppointmentController.getBuyerData';
import getUserData from '@salesforce/apex/AppointmentController.getUserData';
import getResidencePicklist from '@salesforce/apex/AppointmentController.getResidencePicklist';
import getEmiratesPicklist from '@salesforce/apex/AppointmentController.getEmiratesPicklist';
import getNationalitiesPicklist from '@salesforce/apex/AppointmentController.getNationalitiesPicklist';
import getCountyCodePicklist from '@salesforce/apex/AppointmentController.getCountyCodePicklist';
import CancellationReasonPicklist from '@salesforce/apex/AppointmentController.getCancellationReasonPicklist';
import getCustPresencePicklist from '@salesforce/apex/AppointmentController.getCustomerPresencePicklist';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import bookingOnBehalf from '@salesforce/customPermission/EnableAppointMentBookingOnBehalf';
import loggedInUserId from '@salesforce/user/Id';
import USERPROFILE_OBJECT from '@salesforce/schema/User.Profile.Name';
import getProjectLocations from '@salesforce/apex/AppointmentController.getProjectLocations';
import hasFutureAppoitment from '@salesforce/apex/AppointmentController.hasFutureAppoitment';
import getAvailableDates from '@salesforce/apex/AppointmentController.getAvailableDates';
import getAvailableTimeSlots from '@salesforce/apex/AppointmentController.getAvailableTimeSlots';
import bookAppointment from '@salesforce/apex/AppointmentController.bookAppointment';
import cancelAppointment from '@salesforce/apex/AppointmentController.cancelBookedAppointment';
import { CloseActionScreenEvent } from 'lightning/actions';


//START - Cancel Existing Appointment-SARAN
const PROCEED_TO_CANCEL_OK = 'Yes';
const CLOSE_X = 'No';
const BOOKING_SUCCESSFULL='Booking Successful';
// Added By Moh Sarfaraj for ASF-1669 
const SCHEDULE_APPOINTMENT='Schedule Appointment Successfully'
const SCHEDULE_APPOINTMENT_SUCCESSFULLY='Your appointment is scheduled successfully!'
const APPOINTMENT_BOOKING_SUCCESSFULL = 'Your appointment is booked successfully!';
const BOOKING_FAILED='Booking Failed';
const APPOINTMENT_BOOKING_FAILED='Booking Failed ';
const CANCEL_SUCCESSFULL='Booking Cancelled Successful';
const APPOINTMENT_CANCEL_SUCCESSFULL='Your Existing Booking has been Cancelled Successfully';
const CANCEL_FAILED='Booking Cancellation Failed';
const APPOINTMENT_CANCEL_FAILED='Booking Cancellation Failed ';
//END - Cancel Existing Appointment-SARAN

export default class Appointment extends LightningElement {
    /* @api leadId='00Q2600000FgEBVEA3';
    @api opportunityId;
    @api contactId;*/
    @api recordId;
    sObjectRecordType;
    @api userId;//='00526000009A0ivAAC';
    @api forSalesManager;

    nationalities;
    residencies;
    emirates;
    appointmentId;
    userRecord;
    buyerDetails;
    projects;
    selectedProject
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
    disableBooking=false;
    countyCodeValues;

    //START - Cancel Existing Appointment-SARAN
    cancelExistingAppointmentBtnLabel = 'Cancel Existing Appointment';
    askConfirmation = false;
    inputObj = {}; //Generic obj to pass values to confirm modal comp
    xx_modal_class = 'aldar-modal slds-modal slds-fade-in-open xx_confirm_open';//xx_confirm_open;
    cancelReason = null;
    cancelComment = null;
    appointmentRec = {};
    forExistingAppointment = [];
    selectedLocationValue = null;
    submitButtonClass = 'slds-col slds-size_1-of-1 slds-p-around_small';
    cancellationReason = [];
    //END - Cancel Existing Appointment-SARAN
    //Added by Tharun to add Number of Bedrooms
    numberOfBedroomsSelected = '';
    isRescheduleModalOpen = false;
    isRescheduleModalBtnDisabled = true;
	currentUserProfileName;
    customerPresenceOptions;
    isRanTimeSlotAPI = false;
		
		
		// Added by Arvind - hide the email Address and Mobile Number of Contact Center Profile
		
		get userAllowed() {
        return this.currentUserProfileName !== 'Contact Centre Agent';
        }
		
		    @wire(getRecord, { recordId: loggedInUserId, fields: [USERPROFILE_OBJECT] })
				userDetails({ error, data }) {
        if (data) {
            let profileName = getFieldValue(data, USERPROFILE_OBJECT);
            this.currentUserProfileName = profileName;
        } else if (error) {
            this.error = error;
        }
    }


    /* Created Imperative Method this.checkForTheExistingAppointment();
    @wire(hasFutureAppoitment , { recordId: '$recordId' })
    wiredHasFutureAppoitment({ error, data }) {
        if (data) {
            this.disableBooking = data;
        } else if (error) {
            this.disableBooking = false;
        }
    }
    */

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
    @wire(getNationalitiesPicklist )
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
            this.projects = data;
            
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
        this.isLoading = true;
        setTimeout(() => {
            //recordId is not loading immediately while calling from Quick Action, So added timeout for that // SARAN
            this.initRecords();
            this.checkForTheExistingAppointment();
        }, 200);
    }

    checkForTheExistingAppointment() {
        this.isLoading=true;
        hasFutureAppoitment({recordId:this.recordId})
        .then(result => {
            if(result.length!=0) {
                this.appointmentRec = result[0];
                this.disableBooking = result.length!=0;
                this.submitButtonClass = 'slds-col slds-size_1-of-3';
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
        if(this.recordId){
            getBuyerData({ recordId: this.recordId })
            .then(data => {
                for(var key in data){
                    this.sObjectRecordType = key;
                    this.buyerDetails = data[key];
                }
                this.showEmirates=(this.buyerDetails.residence == this.RESIDENTVAL);
                this.numberOfBedroomsSelected = this.buyerDetails.numberOfBedrooms;
                console.log(JSON.stringify(this.buyerDetails));
                this.userId=loggedInUserId;
                this.initUserRecords();
            }).catch(error => {
                this.buyerDetails = undefined;
                this.isLoading=false;
            })
        }else{
            this.isLoading=false;
        }
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

    handleUserIDChange(event){
        this.isLoading=true;
        this.userId = event.target.value;
        this.selectedProject=undefined;
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
        //reset filters below
        //this.template.querySelector(".bookingConfirmationWinReason").value=undefined;
        this.locations = undefined;
        this.selectedLocation=undefined;
        this.selectedLocationValue = undefined;
        this.dates=undefined;
        this.selectedDate=undefined;
        this.slots=undefined;
        this.selectedSlot=undefined;

        getProjectLocations({ userRecord: this.userRecord,projectId : this.selectedProject })
        .then(data => {
            this.locations = data;
            this.isLoading=false;
        }).catch(error => {
            this.locations = undefined;
            this.isLoading=false;
        })
    }
	
    handleLocationChange(event){
        this.isLoading=true;
        this.selectedLocation=event.detail.value;
        this.selectedLocationValue = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.dates=undefined;
        this.selectedDate=undefined;
        this.slots=undefined;
        this.selectedSlot=undefined;

        getAvailableDates({ userRecord: this.userRecord, projectId : this.selectedProject, locationId:this.selectedLocation})
        .then(data => {
            if(data == undefined || data.length == 0 || data == null){
                this.showToast('No Date Slot', 'Sorry, there are no more dates available', 'error');
                this.isLoading = false;
                this.dates = undefined;
            }else{
                this.dates = data;
                this.isLoading = false;
            }
        }).catch(error => {
            this.dates = undefined;
            this.isLoading = false;
        })
    }
	
    handleDateChange(event){
		this.selectedTime = undefined;
        this.isLoading = true;
        this.selectedDate = event.detail.value;
        this.slots = undefined;
        this.selectedSlot = undefined;

        getAvailableTimeSlots({ userRecord: this.userRecord, projectId : this.selectedProject, locationId:this.selectedLocation,selectedDate : this.selectedDate })
        .then(data => {
            // Tharun Added - Check if data contains a Message parameter indicating an error
            if (data && data[0].hasOwnProperty('Message')) {
                console.error('Error message:', data[0].Message);
                this.slots = undefined;
                this.isLoading = false;
                this.showToast('No Time Slot', data[0].Message, 'error');
            } else {
                // Assuming data is correct and slots are available
                this.slots = data;
                this.isLoading = false;
                this.isRanTimeSlotAPI = true;
            }
        }).catch(error => {
            this.slots = undefined;
            this.isLoading=false;
        })
		this.enableRescheduleBtn();
    }
	selectedTime ;
	handleTimeChange(event){
		this.selectedTime = event.target.value;
		this.enableRescheduleBtn();
	}
	
	enableRescheduleBtn(){
		if(this.selectedDate && this.selectedTime){
			this.isRescheduleModalBtnDisabled = false;
		}else{
			this.isRescheduleModalBtnDisabled = true;
		}
	}
	
    handleSubmit(){
        //Validate
        //Callout
        //Create record
        var isError = false;
        let isHavingTimeSlot = true;
        //alert(this.appointmentRec);
        if(this.appointmentRec && this.appointmentRec.Id !== null && this.appointmentRec.Id !== undefined && this.appointmentRec.Id !== ''){
        }else{
            this.template.querySelectorAll('lightning-combobox').forEach(element => {
                element.reportValidity();
                if(element.required && !element.value ){
                    console.log('element.name---',element.name);
                    if(element.name === 'slotId' && this.isRanTimeSlotAPI && (!this.slots || this.slots === undefined || this.slots === null || this.slots === '')){
                        console.log('value---',element.name);
                        const evt = new ShowToastEvent({
                            title: 'No Time Slot',
                            message: 'Time slot is not available for this date',
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        isHavingTimeSlot = false;
                        //return;
                    }else{
                        isError = true;
                    }    
                }
            });
            if(!isHavingTimeSlot){
                return;
            }
            this.template.querySelectorAll('lightning-input').forEach(element => {
                element.reportValidity();
                if(element.required && !element.value ){
                    isError =true;
                    this.activeSections=['UserDetails','BuyerDetails','AppointmentDetails'];
                }
            });
        }
        if(isError){
            const evt = new ShowToastEvent({
                title: 'Reqired Fields Missing',
                message: 'Please populate all the fields before submitting',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }else{
            this.isLoading = true;
            var objectToReturn = {};
           
            if(this.appointmentRec && this.appointmentRec.Id !== null && this.appointmentRec.Id !== undefined && this.appointmentRec.Id !== ''){
                this.template.querySelectorAll('.reschuleBookingDetails').forEach(element => {
                    objectToReturn[element.name] = element.value;
                    if(element.dataset.labelName){
                        objectToReturn[element.dataset.labelName] = element.options.find(opt => opt.value === element.value).label;
                    }
                });

                if(objectToReturn['bookingDate'] == this.appointmentRec.Date__c && objectToReturn['bookingSlot'] == this.appointmentRec.Appointment_Slot_Time__c){
                    console.log(JSON.stringify(objectToReturn));
                    return;
                }
            }else{
                this.template.querySelectorAll('.bookingDetails').forEach(element => {
                    objectToReturn[element.name] =  element.value;
                    if(element.dataset.labelName){
                        objectToReturn[element.dataset.labelName] = element.options.find(opt => opt.value === element.value).label;
                    }
                });
            }

            console.log(objectToReturn);
            //objectToReturn['leadId'] = this.recordId;
            objectToReturn['recordId'] = this.recordId;
            objectToReturn['selectedLocationValue'] = this.selectedLocationValue;
            objectToReturn['numberOfBedrooms'] = this.numberOfBedroomsSelected;
            objectToReturn['accountId'] = this.buyerDetails.accountId;
            objectToReturn['contactId'] = this.buyerDetails.contactId;
            // Added By Moh Sarfaraj for ASF-1669 AppointmentId		
            bookAppointment({ userRecord: this.userRecord, projectId : this.selectedProject, appointmentId : this.appointmentRec.Id, requestInnerMap:objectToReturn })
            .then(data => {
                if(data=='success'){
                    // Added By Moh Sarfaraj for ASF-1669 
                    // schedule Appointment 
                    if(this.appointmentRec.Id){
                        setTimeout(() => {
                            this.closeRescheduleModalHandle();
                            this.closeQuickAction();
                        }, 1200);

                        const evt = new ShowToastEvent({
                            title: SCHEDULE_APPOINTMENT,
                            message: SCHEDULE_APPOINTMENT_SUCCESSFULLY,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        
                    }else
										{ // Appointment Booking
                        const evt = new ShowToastEvent({
                            title: BOOKING_SUCCESSFULL,
                            message: APPOINTMENT_BOOKING_SUCCESSFULL,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                    }
                    this.checkForTheExistingAppointment();
                    this.doReset();//Reset the form values
                    this.disableBooking=true;
                    this.submitButtonClass = 'slds-col slds-size_1-of-2';
                }else{
                    const evt = new ShowToastEvent({
                        title: BOOKING_FAILED,
                        message: APPOINTMENT_BOOKING_FAILED+data,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading=false;
            }).catch(error => {
                 const evt = new ShowToastEvent({
                    title: BOOKING_FAILED,
                    message: APPOINTMENT_BOOKING_FAILED+JSON.stringify(error),
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.isLoading=false;
            })
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
    }

    handleReschedule(){
        this.selectedProject = this.appointmentRec.Project__c ;
        this.selectedLocation = this.appointmentRec.Location__c;
        
        getAvailableDates({ userRecord: this.userRecord, projectId : this.selectedProject, locationId:this.selectedLocation})
        .then(data => {
            this.dates = data;
            this.isLoading = false;
        }).catch(error => {
            this.dates = undefined;
            this.isLoading = false;
        })
        this.isRescheduleModalOpen = true;
    }

    closeRescheduleModalHandle(){
		this.isRescheduleModalBtnDisabled = true;
        this.isRescheduleModalOpen = false;
        this.selectedProject = undefined;
        this.selectedLocation = undefined;
		this.slots = undefined;
		this.dates = undefined;
		this.selectedDate = undefined;
		this.selectedTime =  undefined;
    }

    doReset() {
        this.template.querySelectorAll('lightning-combobox[data-id="booking_form"]').forEach(element => {
            element.value = null;
        });
        this.template.querySelectorAll('lightning-textarea[data-id="booking_form"]').forEach(element => {
            element.value = null;
        });
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
            inputObj.forSalesManager = this.forSalesManager;
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
                this.submitButtonClass = 'slds-col slds-size_1-of-1 slds-p-around_small';
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}