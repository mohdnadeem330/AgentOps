import { api, LightningElement } from 'lwc';

export default class DataTableCell extends LightningElement {
    @api parentRecord = {};
    @api record = {};
    @api column = {};
    @api recordIndex;
    @api columnIndex;
    @api accountList = [];
    @api salesOrderList = [];
    @api lineList = [];
    @api relationTypeList = [];
    @api tableType = '';

    connectedCallback() { }

    handleChange(event) {
        let val = event.target.value ? event.target.value : event.detail.value;
        const selectedEvent = new CustomEvent('changevalue', {
            detail: {
                recordIndex: this.recordIndex,
                fieldName: event.target.name,
                value: val,
                tableType: this.tableType
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    deleteAllocation(event) {
        const selectedEvent = new CustomEvent('deleteallocation', {
            detail: {
                recordIndex: this.recordIndex,
                tableType: this.tableType
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    get value() {
        // if (this.isPicklist) {
        //     let fieldName = this.column.fieldName;
        //     if (fieldName == 'account') {
        //         this.options = this.accountList ? JSON.parse(JSON.stringify(this.accountList)) : [];
        //     } else if (fieldName == 'unitNumber') {
        //         this.options = this.salesOrderList && this.salesOrderList.hasOwnProperty(this.record.accountId) ? JSON.parse(JSON.stringify(this.salesOrderList[this.record.accountId])) : [];
        //     } else if (fieldName == 'installmentOtherCharges') {
        //         this.options = this.lineList ? JSON.parse(JSON.stringify(this.lineList)) : [];
        //     }
        // }
        return this.column.type != 'button' && (this.record[this.column.fieldName] != undefined || this.record[this.column.fieldName] != null) ? this.record[this.column.fieldName] : '';
    }

    get options() {
        let optionList = [];
        if (this.isPicklist) {
            let fieldName = this.column.fieldName;
            if (fieldName == 'account') {
                optionList = this.accountList ? JSON.parse(JSON.stringify(this.accountList)) : [];
            } else if (fieldName == 'unitNumber') {
                optionList = this.salesOrderList && this.salesOrderList.hasOwnProperty(this.record.accountId) ? JSON.parse(JSON.stringify(this.salesOrderList[this.record.accountId])) : [];
            } else if (fieldName == 'installmentNoOtherCharge') {
                let uniqeId = this.record.accountId + '_' + this.record.salesOrderId;
                console.log('uniqeId>>>' + uniqeId);
                optionList = this.lineList && this.lineList.hasOwnProperty(uniqeId) ? JSON.parse(JSON.stringify(this.lineList[uniqeId])) : [];
            } else if (fieldName == 'jointOwner') {
                optionList = this.accountList ? JSON.parse(JSON.stringify(this.accountList)) : [];
            } else if (fieldName == 'newRelationType') {
                optionList = this.relationTypeList ? JSON.parse(JSON.stringify(this.relationTypeList)) : [];
            }
        }
        return optionList;
    }

    get isReadonly() {
        return this.column.readonly || (this.record && this.record.Id && this.column.fieldName != 'amountApplied' && this.column.fieldName != 'sharePercentage' && this.column.fieldName != 'newRelationType') ? true : false;
    }

    get isText() {
        return (this.column.type == 'picklist-text' && this.record && this.record.Id && this.column.fieldName != 'newRelationType') || this.column.type == 'text' ? true : false;
    }

    get isPicklist() {
        return this.column.type == 'picklist-text' && this.record && (!this.record.Id || this.column.fieldName == 'newRelationType') ? true : false;
    }

    get isCurrency() {
        return this.column.type == 'currency' ? true : false;
    }

    get isPercent() {
        return this.column.type == 'percent' ? true : false;
    }

    get isButton() {
        return this.column.type == 'button' ? true : false;
    }

    get isDelete() {
        if (this.record && this.record.hasOwnProperty('jointOwnerId') && (this.record.jointOwnerId == undefined || this.record.jointOwnerId == null || this.record.jointOwnerId == '')) {
            return true;
        }
        return this.record && !this.record.Id ? true : false;
    }
}