import { LightningElement } from 'lwc';

export default class CustomerSatisfactionRating extends LightningElement {

    tableColumns = [
        {
            type: 'text',
            fieldName: 'score',
            label: 'Score',
            // initialWidth: 200,
            cellAttributes: { class: 'score-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'clientName',
            label: 'Client Name',
            // initialWidth: 100,
            cellAttributes: { class: 'client-name-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'project',
            label: 'Project',
            // initialWidth: 100,
            cellAttributes: { class: 'project-cell' /*important for reponsive */ }
        },
        {
            type: 'text',
            fieldName: 'receivedDate',
            label: 'Received Date',
            cellAttributes: { class: 'received-date-cell' /*important for reponsive */ }
        }

    ];


    tableData=[
        {
            id: 1,
            score:"1",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 2,
            score:"2",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 3,
            score:"3",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 4,
            score:"4",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },{
            id: 5,
            score:"5",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 6,
            score:"6",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 7,
            score:"7",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        },
        {
            id: 8,
            score:"8",
            clientName:"Test 1",
            project:"Tesg",
            receivedDate:"sdfsdfsdf"
        }
    ];

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }
}