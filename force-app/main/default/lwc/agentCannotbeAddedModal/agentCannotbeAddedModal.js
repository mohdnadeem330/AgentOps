import { LightningElement, api } from 'lwc';

export default class AgentCannotbeAddedModal extends LightningElement
{
    @api    userTrailmixRecords = [];

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false, new: this.new } }));
    }
}