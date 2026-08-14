import StudentList from '../components/StudentList';

function Home({ searchValue = '' }) {
  return <StudentList searchValue={searchValue} />;
}

export default Home;
