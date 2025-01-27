
import { Delete, Edit } from '@mui/icons-material';
import { IconButton, List, ListItem, ListItemText } from '@mui/material';

const MyListItem = (props: { text: any, onEdit: Function, onDelete: Function }) => {
      return (
        <ListItem
        secondaryAction={
          <>
            <IconButton edge="end" aria-label="edit" onClick={() => props.onEdit()}>
              <Edit />
            </IconButton>
            <IconButton edge="end" aria-label="delete" onClick={() => props.onDelete()}>
              <Delete />
            </IconButton>
          </>
        }
      >
        <ListItemText primary={props.text} />
      </ListItem>
  )
};
  
  const MyList = (props: { items: any, handleEdit: Function , handleDelete: Function }) => (
    <List>
      {props.items.map((item: any, index: any) => (
        <MyListItem
          key={index}
          text={item}
          onEdit={() => props.handleEdit(index)}
          onDelete={() => props.handleDelete(index)}
        />
      ))}
    </List>

    );
    
export default MyList;



import { useState } from 'react'
import './App.css'
import MyList from './component/MyList';

const App = () => {
  const [items, setItems] = useState(['Item 1', 'Item 2', 'Item 3']);

  const handleEdit = (index: any) => {
    // Your edit logic here
    console.log(`Edit item at index: ${index}`);
  };

  const handleDelete = (index: number) => {
    // Your delete logic here
    const newItems = items.filter((_, i) => i !== index);
    setItems(newItems);
  };

  return <MyList items={items} handleEdit={handleEdit} handleDelete={handleDelete} />;
};

export default App;
