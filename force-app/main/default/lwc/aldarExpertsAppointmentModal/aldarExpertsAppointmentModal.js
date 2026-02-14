import { LightningElement, track, wire, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import loggedInUser from "@salesforce/user/Id";
import getCountyCodePicklist from '@salesforce/apex/AppointmentController.getCountyCodePicklist';
import getCancellationReasonPicklist from '@salesforce/apex/AppointmentController.getCancellationReasonPicklist';
import getUserData from '@salesforce/apex/AppointmentController.getUserData';
import getAllAppointments from '@salesforce/apex/AppointmentController.getEventAllAppointments';
import getEventProjects from '@salesforce/apex/AppointmentController.getEventProjects';
import getProjectDetails from '@salesforce/apex/AppointmentController.getEventProjectDetails';
import getProjectLocations from '@salesforce/apex/AppointmentController.getEventProjectLocations';
import getEventAvailableDates from '@salesforce/apex/AppointmentController.getEventAvailableDates';
import getEventAvailableTimeSlots from '@salesforce/apex/AppointmentController.getEventAvailableTimeSlots';
import bookEventAppointment from '@salesforce/apex/AppointmentController.bookEventAppointment';
import cancelBookedAppointment from '@salesforce/apex/AppointmentController.cancelBookedAppointment'; 
import bookedContentLabel from '@salesforce/label/c.BookedContent';

const BOOKING_SUCCESSFULL = 'Thank you for registering your interest!';
// const APPOINTMENT_BOOKING_SUCCESSFULL = 'Your Appointment ';
const BOOKING_FAILED = 'Booking Failed';
const APPOINTMENT_BOOKING_FAILED = 'Booking Failed ';
const CANCEL_SUCCESSFULL = 'Booking Cancelled Successful';
const APPOINTMENT_CANCEL_SUCCESSFULL = 'Your Existing Booking has been Cancelled Successfully';
const CANCEL_FAILED = 'Booking Cancellation Failed';
const APPOINTMENT_CANCEL_FAILED = 'Booking Cancellation Failed ';
// import { APPOINTMENT_COLUMNS } from './sampleData';

const APPOINTMENT_COLUMNS = [
    { type: 'text', fieldName: 'AppointmentId__c', label: 'Appointment Number'},
    { type: 'text', fieldName: 'EventName__c', label: 'Event Name'},
    { type: 'text', fieldName: 'Date__c', label: 'Date'},
    { type: 'text', fieldName: 'Appointment_Slot_Time__c', label: 'Time'},
    { type: 'text', fieldName: 'Appointment_Location__c', label: 'Location'},
    { type: 'text', fieldName: 'Appointment_Status__c', label: 'Status'},
    { type: "button", label: 'Action', initialWidth: 110, 
        typeAttributes: {
            label: 'Cancel',
            name: 'Cancel',
            title: 'Cancel',
            disabled: {fieldName : 'buttonDisabled'},
            value: 'delete',
            iconPosition: 'left',
            variant:'destructive'
        }
    }
]  

// Added by Moh Sarfaraj for BPE-242
const monthsMap = new Map([
    ['01', 'Jan'],
    ['02', 'Feb'],
    ['03', 'Mar'],
    ['04', 'April'],
    ['05', 'May'],
    ['06', 'Jun'],
    ['07', 'Jul'],
    ['08', 'Aug'],
    ['09', 'Sept'],
    ['10', 'Oct'],
    ['11', 'Nov'],
    ['12', 'Dec'],
  ]);

export default class AldarExpertsAppointmentModal extends LightningElement {
    @track appointmentColumns = APPOINTMENT_COLUMNS;
    @track bookedContentLabel = [];
    @track brokerId; @track userRecord; @track hasAppointment; @track selectedLocation;
    @track selectedLocationValue; @track dates; @track selectedDate; @track slots;
    @track selectedSlot; @track locations; @track selectedProject; @track countyCodeValues;
    @track cancellationReason;
    @track projects = []; @track isAssigned = false; @track isLoading = true; @track disableBooking = false;
    @track isUpdateUserDetails = false; @track showCancelReasons = false;
    @track inputObj = {}; @track cancelReason = null; @track cancelComment = null;
    @track xx_modal_class = 'aldar-modal slds-modal slds-fade-in-open xx_confirm_open';
    @track activeSections = ['AppointmentDetails']; @track allAppointments = [];
    @track recordId = loggedInUser; @track isBlockedAppointment = false; @track activeTab = "One"; 
    @track doSetProjLocDate = false; disabledTimeSlot = true;
    selectedProjectId;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;

        if (currentPageReference.state) {
            this.activeTab = currentPageReference.state.c__activeTab;
        }
    }

    @wire(getCountyCodePicklist)
    wiredCountyCodePicklist({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.countyCodeValues = data;
            this.isLoading = false;
        } else if (error) {
            this.countyCodeValues = undefined;
            this.isLoading = false;
        }
    }

    @wire(getUserData, {recordId : '$recordId'})
    getUserDetails({error, data}){
        this.isLoading = true;
        if(data){
            this.userRecord = data;
            this.isLoading = false;
        }else if(error){
            this.userRecord = undefined;
            this.isLoading = false;
        }
    }   

    @wire(getCancellationReasonPicklist)
    wiredCancellationReasonPicklist({ error, data }) {
        if(data){
            let newOptions = [];
            for(let i in data){
                newOptions.push({label:data[i].label, value:data[i].label});
            }
            this.cancellationReason = null;
            this.cancellationReason = newOptions;
        }else if(error) {
            this.cancellationReason = undefined;
        }
    }

    // @wire(getAllAppointments, {recordId :'$userRecord.ContactId'})
    // getAppointments({error, data}){
    //     this.isLoading = true;
    //     if(data){
    //         if(data.length != 0 || data.length > 0){
    //             this.allAppointments = data;
    //             this.isLoading = true;
              
    //             if(data[0].Appointment_Status__c === 'Cancelled' && data[0].IsCancelledByManager__c == true){
    //                 this.isBlockedAppointment = true;
    //                 this.isLoading = false;
    //             }else if(data[0].Appointment_Status__c === 'Booked'){
    //                 this.isBlockedAppointment = false;   
    //                 this.hasAppointment = data[0];
    //                 this.disableBooking = true;
    //                 this.isLoading = false;
    //             }else {
    //                 this.hasAppointment = {};
    //                 this.isLoading = false;
    //             }
    //             this.allAppointments = this.allAppointments.map((app) => ({ ...app, buttonDisabled : 'Cancelled' == app.Appointment_Status__c }));
    //             this.isAssigned = true;
    //         }
    //         this.isAssigned = true;
    //         this.isLoading = false;
    //     }else if(error){
    //         this.hasAppointment = {};
    //         this.isLoading = false;
    //         this.isAssigned = true;
    //     }
    // }
    // Added by Moh Sarfaraj for BPE-242
    appointmentFormatedDate;
    appointmentFormatedTime;
    eventName;
    getAllAppts(){
        getAllAppointments({recordId : this.userRecord.ContactId})
        .then(data=>{
            if(data.length != 0 || data.length > 0){
                this.allAppointments = data;
                this.isLoading = true;
              
                if(data[0].Appointment_Status__c === 'Cancelled' && data[0].IsCancelledByManager__c == true){
                    this.isBlockedAppointment = true;
                    this.isLoading = false;
                }else if(data[0].Appointment_Status__c === 'Booked'){
                    this.isBlockedAppointment = false;   
                    this.hasAppointment = data[0];
                    this.eventName = data[0].EventName__c;
                    this.disableBooking = true;
                    this.isLoading = false;
                    
                    
                    // Added by Moh Sarfaraj for BPE-242
                    const dateArray = data[0].Date__c.split('-'); // year month day
                    let month = monthsMap.get(dateArray[1]);
                    this.appointmentFormatedDate = month + ' ' + dateArray[2] + ', ' + dateArray[0];
                    this.appointmentFormatedTime = (data[0].Appointment_Slot_Time__c.split('-'))[0].trim();
                    
                }else {
                    this.hasAppointment = {};
                    this.isLoading = false;
                }
                this.allAppointments = this.allAppointments.map((app) => ({ ...app, buttonDisabled : 'Cancelled' == app.Appointment_Status__c }));
                this.isAssigned = true;
            }
            this.isAssigned = true;
            this.isLoading = false;
        }).catch(error=>{
            this.hasAppointment = {};
            this.isLoading = false;
            this.isAssigned = true;
        })
    }

    async connectedCallback(){
        this.doSetProjLocDate = true;
        this.isLoading = true;
        this.bookedContentLabel = bookedContentLabel.split(',');
        // To get the Prpject Name, Location, Date and Timeslots in the chain.
        // this.getProjectsUtility();

        getEventProjects({})
        .then(results=>{
            this.projects = results;
        }).catch(error=>{
            this.projects = [];
        })

        setTimeout(()=>{
            this.getAllAppts();
        }, 1000)
    }

    getProjectsUtility(){
        getProjectDetails({
            projectName : this.selectedProject
        }).then(results=>{
            // this.projects = results;
            this.selectedProjectId = results[0].value
            this.getProjectLocationsUtility();
        }).catch(error=>{
            // this.projects = [];
            this.isLoading = false;
        })
    }
    
    async handleProjectChange(event){
        this.doSetProjLocDate = false; 
        this.isLoading = true;
        this.selectedProject = event.detail.value;
        // this.getProjectLocationsUtility(); 
        this.getProjectsUtility();  
    }

    async getProjectLocationsUtility(){
        this.isLoading = true;
        this.locations = undefined;
        this.selectedLocation = undefined;
        this.dates = undefined;
        this.selectedDate = undefined;
        this.slots = undefined;
        this.selectedSlot = undefined;

        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            if(each.name === 'locationId' || each.name === 'bookingDate' || each.name === 'slotId'){
                each.value = null;
            }
        });
                
        await getProjectLocations({ userRecord : this.userRecord, projectId : this.selectedProjectId })
        .then(data => {
            if(data == undefined || data.length == 0 || data == null){
                if(!this.isBlockedAppointment && !this.hasAppointment){
                    const evt = new ShowToastEvent({
                        title: 'No Locations',
                        message: 'Appointment opening soon.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;
            }else{
                this.locations = data;
                this.selectedLocation = data[0].value;
                this.selectedLocationValue = data[0].label;
                this.getEventAvailableDatesUtility();
                if(!this.doSetProjLocDate){
                    this.isLoading = false;
                }
            }
        }).catch(error => {
            if(!this.isBlockedAppointment && !this.hasAppointment){
                const evt = new ShowToastEvent({
                    title: 'No Locations',
                    message: 'Appointment opening soon.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            this.locations = undefined;
            this.isLoading = false;
        })
    }

    async handleLocationChange(event){
        this.isLoading = true;
        this.doSetProjLocDate = false;
        this.selectedLocation = event.detail.value;
        this.selectedLocationValue = event.target.options.find(opt => opt.value === event.detail.value).label;
        await this.getEventAvailableDatesUtility();
    }

    async getEventAvailableDatesUtility(){
        this.isLoading = true;
        this.dates = undefined;
        this.selectedDate = undefined;
        this.slots = undefined;
        this.selectedSlot = undefined;

        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            if(each.name === 'bookingDate' || each.name === 'slotId'){
                each.value = null;
            }
        });
        
        await getEventAvailableDates({ 
            userRecord : this.userRecord, 
            locationId : this.selectedLocation, 
            projectName : this.selectedProject
        }
        )
        .then(data => {
            if(data == undefined || data.length == 0 || data == null){
                if(!this.isBlockedAppointment && !this.hasAppointment){
                    const evt = new ShowToastEvent({
                        title: 'No Date Slot',
                        message: 'Appointment opening soon.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;
            }else{
                this.dates = data;
                this.selectedDate = data[0].value;
                if(!this.doSetProjLocDate){
                    this.isLoading = false;
                }
                this.handleDateChangeUtility();
            }
        }).catch(error => {
            if(!this.isBlockedAppointment && !this.hasAppointment){
                const evt = new ShowToastEvent({
                    title: 'No Date Slot',
                    message: 'Appointment opening soon.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            this.dates = undefined;
            this.isLoading = false;
        })
    }

    async handleDateChange(event){
        this.isLoading = true;
        this.selectedDate = event.detail.value;
        await this.handleDateChangeUtility();
    }

    async handleDateChangeUtility(){
        this.isLoading = true;
        this.slots = undefined;
        this.selectedSlot = undefined;

        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            if(each.name === 'slotId'){
                each.value = null;
            }
        });

        await getEventAvailableTimeSlots({ 
            userRecord : this.userRecord, 
            locationId : this.selectedLocation, 
            selectedDate : this.selectedDate, 
            projectName : this.selectedProject
        })
        .then(data => {
            if(data == undefined || data.length == 0 || data == null){
                this.disabledTimeSlot = false;
                if(!this.isBlockedAppointment && !this.hasAppointment){
                    const evt = new ShowToastEvent({
                        title: 'No Time Slot',
                        message: 'Appointment opening soon.',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;
            }else{ 
                this.slots = data;
                this.selectedSlot = data[0].value;
                this.disabledTimeSlot = true;
                this.isLoading = false;
            }
        }).catch(error => {
            this.disabledTimeSlot = false;
            if(!this.isBlockedAppointment && !this.hasAppointment){
                const evt = new ShowToastEvent({
                    title: 'No Time Slot',
                    message: 'Appointment opening soon.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            this.slots = undefined;
            this.isLoading = false;
        })
    }

    handleSubmit(){
        var isError = false;
        let userValue = false;
        let appointValue = false;
        
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
                userValue = true;
            }
        });
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
                appointValue  = true;
            }
        });
        if(isError){
            this.activeSections = userValue ? ['UserDetails'] : appointValue ? ['AppointmentDetails'] : [];
             
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
            this.template.querySelectorAll('.bookingDetails').forEach(element => {
                if(element.name === 'phoneCountryCode'){
                    objectToReturn[element.name] = element.value.replace('+', '');
                } else {
                    objectToReturn[element.name] = element.value;
                }
                if(element.dataset.labelName){
                    objectToReturn[element.dataset.labelName] = element.options.find(opt => opt.value === element.value).label;
                }
            });

            objectToReturn['bookingSource'] = 'OnlineBroker';
            objectToReturn['projectCode'] = this.selectedProject;
            objectToReturn['slotType'] = 'Public';
            objectToReturn['categoryName'] = 'Events'; 
            objectToReturn['passportNumber'] = null;
            objectToReturn['agencyId'] = this.userRecord.Account.AppointmentSystemID__c;
            objectToReturn['agentId'] = this.userRecord.Contact.AgentID__c;
            objectToReturn['selectedLocationValue'] = this.selectedLocationValue;
            objectToReturn['residencyStatus'] = this.userRecord.Contact.ResidentStatus__c;
            objectToReturn['nationality'] = this.userRecord.Contact.CountryOfResidence__c;
            objectToReturn['nationalityCode'] = this.userRecord.Contact.MailingCountryCode;
            objectToReturn['emiratesId'] = this.userRecord.Contact.NationalIdNumber__c; 
            objectToReturn['projectName'] = this.selectedProject; 

            if(!this.userRecord.Contact.MobileCountryCode__c || !this.userRecord.Contact.MobilePhone__c){
                this.isUpdateUserDetails = true;
            }

            bookEventAppointment({ userRecord: this.userRecord, requestInnerMap : objectToReturn, isUpdateUserDetails : this.isUpdateUserDetails })
            .then(data => {
                let dataObj = {};
                if(data.includes('result')){
                    dataObj = JSON.parse(data);
                }
                if(dataObj.result == 'success'){
                    this.getAllAppts();
                    const evt = new ShowToastEvent({
                        title: BOOKING_SUCCESSFULL,
                        message: 'Stay tuned for your appointment confirmation email.',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.disableBooking = true;
                    this.closeModal();
                    this.isLoading = false;
                    //window.location.replace("../s");
                }else{
                    const evt = new ShowToastEvent({
                        title: BOOKING_FAILED,
                        message: APPOINTMENT_BOOKING_FAILED+data,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                }
            }).catch(error => {
                console.log(JSON.stringify(error));
                const evt = new ShowToastEvent({
                    title: BOOKING_FAILED,
                    message: APPOINTMENT_BOOKING_FAILED+error.body.message, 
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })
        }
    }

    handleCancelAppointment(event) {
        this.showCancelReasons = true;
        this.isAssigned = false;
    }

    handleBack(event){
        this.showCancelReasons = false;
        this.isAssigned = true;
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
        this.isLoading = true;
        var objectToReturn = {};
        objectToReturn['cancelreason'] = this.cancelReason;
        objectToReturn['message'] = this.cancelComment;
        console.log(objectToReturn);
        let isError = false;

        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
            }
        });
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value){
                isError = true;
            }
        });
        if(isError){
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Reqired Fields Missing',
                message: 'Please populate all the fields before cancel',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }else {
            cancelBookedAppointment({ recordId : this.userRecord.ContactId, requestInnerMap : objectToReturn })
            .then(data => {
                if(data == 'success'){
                    this.getAllAppts();
                    const evt = new ShowToastEvent({
                        title: CANCEL_SUCCESSFULL,
                        message: APPOINTMENT_CANCEL_SUCCESSFULL,
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.closeModal();
                    //window.location.replace("../s");
                } else{
                    const evt = new ShowToastEvent({
                        title: CANCEL_FAILED,
                        message: APPOINTMENT_CANCEL_FAILED+data,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                this.isLoading = false;
            }).catch(error => {
                    const evt = new ShowToastEvent({
                    title: CANCEL_FAILED,
                    message: APPOINTMENT_CANCEL_FAILED+JSON.stringify(error),
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })   
        }    
    }

    handleRowAction(event){
        this.handleCancelAppointment();
        this.activeTab = 'One'
        this[NavigationMixin.Navigate](
            this.getUpdatedPageReference({
                c__activeTab: this.activeTab
            }),
            true 
        );
    }

    handleActiveAppointment(event){
        this.activeTab = "One"; 
    }

    handleActiveMyAppointments(event){
        this.activeTab = "Two"; 
    }

    getUpdatedPageReference(stateChanges) {
        return Object.assign({}, this.currentPageReference, {
            state: Object.assign(
                {},
                this.currentPageReference.state,
                stateChanges
            )
        });
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('close',{detail:{isOpen:false}}));
    }
}