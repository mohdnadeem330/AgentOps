import { LightningElement, api, track, wire } from 'lwc';

export default class AppointmentCannotbeBookedModal extends LightningElement 
{
    @api    userTrailmixRecords = [];


    connectedCallback()
    {
        //this.multipleURLs = this.trailmixExternalUrl.split(',');
        //alert(this.multipleURLs);
        //Object.values(this.label)[0].split(',');
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false, new: this.new } }));
    }
}