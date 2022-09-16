import WordCloud from 'react-d3-cloud';

const data = [
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
  { text: 'root', value: 1000 },
  { text: 'admin', value: 200 },
  { text: 'postgres', value: 800 },
  { text: 'test', value: 1000000 },
  { text: 'mysql', value: 2000 },
];
export const WordCloudComponent = () => (
   <WordCloud data={data} />
)