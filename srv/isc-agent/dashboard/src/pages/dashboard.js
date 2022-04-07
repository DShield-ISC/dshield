import {Card, CardContent, CardHeader, Grid, IconButton, Typography} from "@mui/material";
import {DoughnutChart} from "../components/DoughnutChart";
import {VerticalBarChart} from "../components/VerticalBarChart";
import {SimpleCloud} from "../components/WordCloudComponent2";
import MapChart from "../components/WorldMap";
// style={{ backgroundColor: "red"}}
const Dashboard = () => {

    return (
        <div>
            <Grid container>
                <Grid container item xs={6} spacing={1}>
                    <Grid item xs={12} sm={6} xl={4} >
                        <DoughnutChart />
                    </Grid>
                    <Grid item xs={12} sm={6} xl={4}>
                        <DoughnutChart />
                    </Grid>
                     <Grid xs={12} sm={6} xl={4}>
                        <DoughnutChart />
                    </Grid>
                     <Grid xs={12} sm={6} xl={4}>
                        <DoughnutChart />
                    </Grid>
                    <Grid xs={12} sm={6} xl={4}>
                        <DoughnutChart />
                    </Grid>
                    <Grid xs={12} sm={6} xl={4}>
                        <DoughnutChart />
                    </Grid>
                </Grid>
                <Grid container item xs={6}>
                    <Grid item xs={12}>
                        <VerticalBarChart />
                    </Grid>
                    <Grid item xs={12}>
                        <SimpleCloud />
                    </Grid>
                </Grid>
                <Grid container xs={6} lg={3} >
                    <Grid item xs={12}>
                        <MapChart />
                    </Grid>
                </Grid>
            </Grid>
        </div>

    )
}

export default Dashboard;