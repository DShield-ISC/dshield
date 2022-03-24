import logo from './logo.svg';
import './App.css';
import { Button } from "@mui/material";
import React from 'react';
import { makeStyles} from "@material-ui/core";
import Paper from '@material-ui/core/Paper';
import Grid from '@material-ui/core/Grid';
import {Card} from "@material-ui/core";
import { CardActionArea, CardMedia, CardContent, Typography, CardActions } from "@material-ui/core";

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
  },
  paper: {
    padding: theme.spacing(2),
    textAlign: 'center',
    color: theme.palette.text.secondary,
  },
}));


function App() {
  return (
   <AutoGrid />
  );
}

export default App;


function AutoGrid() {
  const classes = useStyles();

  return (
    <div className={classes.root}>
      <Grid container spacing={3}>
        <Grid item xs>
          <Paper className={classes.paper}><MediaCard /></Paper>
        </Grid>
        <Grid item xs>
          <Paper className={classes.paper}><MediaCard2 /></Paper>
        </Grid>
        <Grid item xs>
          <Paper className={classes.paper}><MediaCard /></Paper>
        </Grid>
      </Grid>
      <Grid container spacing={3}>
        <Grid item xs>
          <Paper className={classes.paper}><MediaCard2 /></Paper>
        </Grid>
        <Grid item xs={6}>
          <Paper className={classes.paper}><MediaCard /></Paper>
        </Grid>
        <Grid item xs>
          <Paper className={classes.paper}><MediaCard2 /></Paper>
        </Grid>
      </Grid>
    </div>
  );
}

function MediaCard(cardTitle, number) {
  const classes = useStyles();

  return (
    <Card className={classes.root}>
      <CardActionArea>
        <CardContent>
          <Typography gutterBottom variant="h5" component="h2">
            Requests
          </Typography>
          <Typography variant="h6">
              15
          </Typography>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}

function MediaCard2(cardTitle, number) {
  const classes = useStyles();

  return (
    <Card className={classes.root}>
      <CardActionArea>
        <CardContent>
          <Typography gutterBottom variant="h5" component="h2">
            Get Requests
          </Typography>
          <Typography variant="h6">
              25
          </Typography>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}