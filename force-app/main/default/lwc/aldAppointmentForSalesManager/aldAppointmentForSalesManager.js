import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AldAppointmentForSalesManager extends LightningElement {
    @api recordId;
    forManager = true;
    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}