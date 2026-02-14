import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
// import { RefreshEvent } from 'lightning/refresh';
// import { NavigationMixin } from 'lightning/navigation';

import cancelBookedAppointment from '@salesforce/apex/AppointmentController.cancelBookedAppointmentFromQuickAction';

const CANCEL_SUCCESSFULL = 'Booking Cancelled Successful';
const APPOINTMENT_CANCEL_SUCCESSFULL = 'Your Existing Booking has been Cancelled Successfully';
const CANCEL_FAILED = 'Booking Cancellation Failed';
const APPOINTMENT_CANCEL_FAILED = 'Booking Cancellation Failed ';

export default class AldarExpertCancelAppointment extends LightningElement {
    @track isLoading = true;
    @api recordId;

    connectedCallback(){
        setTimeout(() => {
            if(this.recordId){
                cancelBookedAppointment({ recordId : this.recordId })
                .then(data=>{
                    if(data == 'success'){
                        const evt = new ShowToastEvent({
                            title: CANCEL_SUCCESSFULL,
                            message: APPOINTMENT_CANCEL_SUCCESSFULL,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        this.closeQuickAction();
                        this.isLoading = false;
                    } else{
                        const evt = new ShowToastEvent({
                            title: CANCEL_FAILED,
                            message: data,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        this.closeQuickAction();
                        this.isLoading = false;
                    }
                    this.isLoading = false;
                })
                .catch(error=>{
                    const evt = new ShowToastEvent({
                        title: CANCEL_FAILED,
                        message: APPOINTMENT_CANCEL_FAILED+JSON.stringify(error),
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                    this.closeQuickAction();
                    this.isLoading = false;
                })
            }
        }, 5);
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}